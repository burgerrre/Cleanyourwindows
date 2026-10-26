. (Join-Path $PSScriptRoot 'Debloat.Menu.ps1')

function Get-WebCatalog([switch]$Demo) {
    $previous=$env:DEBLOAT_LANGUAGE
    Set-UiLanguage RU; $ru=@(Get-DebloatCatalog)
    Set-UiLanguage EN; $en=@(Get-DebloatCatalog)
    $env:DEBLOAT_LANGUAGE=$previous
    $installed=@();$provisioned=@();$desktop=@()
    if (-not $Demo) {
        $installed=@(Get-AppxPackage -AllUsers -ErrorAction Stop)
        $provisioned=@(Get-AppxProvisionedPackage -Online -ErrorAction Stop)
        foreach ($root in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
            $desktop+=@(Get-ItemProperty -Path $root -ErrorAction SilentlyContinue | Where-Object { $_.PSObject.Properties['DisplayName'] } | Select-Object -ExpandProperty DisplayName)
        }
    }
    $removal=@(for ($i=0;$i -lt $ru.Count;$i++) {
        $app=$ru[$i]
        $found=@($installed | Where-Object { $_.Name -in $app.Packages }).Count -gt 0 -or @($provisioned | Where-Object { $_.DisplayName -in $app.Packages }).Count -gt 0
        if ($app.Id -eq 'edge' -and 'Microsoft Edge' -in $desktop) { $found=$true }
        if ($app.Id -eq 'office' -and @($desktop | Where-Object {$_ -match '^Microsoft 365(?:\s|$)'}).Count) { $found=$true }
        if ($app.Id -eq 'copilot' -and @($desktop | Where-Object {$_ -in @('Microsoft Copilot','Copilot')}).Count) { $found=$true }
        if ($Demo) { $found=$app.Id -in @('edge','office','copilot','clipchamp','news','xbox','teams','phone','solitaire') }
        [pscustomobject]@{id=$app.Id;nameRU=$app.Title;nameEN=$en[$i].Title;noteRU=$app.Note;noteEN=$en[$i].Note;detected=[bool]$found}
    })
    $categories=@{firefox='browser';vlc='media';obs='media';tgwsproxy='network';zapret='network';discord='communication';vencord='communication';happ='network';'7zip'='tools';steam='gaming';prism='gaming';codex='coding';antigravity='coding';claude='coding';telegram='communication';codexcli='coding'}
    $installation=@(Get-InstallCatalog | ForEach-Object { [pscustomobject]@{id=$_.Id;name=$_.Name;noteRU=$_.NoteRU;noteEN=$_.NoteEN;category=$categories[$_.Id];dependencies=@($_.Dependencies);provider=$_.Provider} })
    $disk=[IO.DriveInfo]::new($env:SystemDrive+'\')
    if ($Demo) {$disk=[pscustomobject]@{AvailableFreeSpace=[long](186.4GB);TotalSize=[long](476.8GB)}}
    $platform=[pscustomobject]@{caption='Windows 11 Pro';build=26100;serverRemoval=$false}
    if (-not $Demo) { $os=Get-DefenderPlatform; $platform=[pscustomobject]@{caption=$os.Caption;build=$os.Build;serverRemoval=$os.Supported} }
    [pscustomobject]@{removal=$removal;installation=$installation;system=$platform;disk=[pscustomobject]@{name=$env:SystemDrive;free=[long]$disk.AvailableFreeSpace;total=[long]$disk.TotalSize};demo=[bool]$Demo}
}

function Test-WebAction($Request) {
    if (-not $Request.PSObject.Properties['action'] -or $Request.action -notin @('uninstall','install','repairWinget','security','serverSecurity')) { throw 'Unsupported action.' }
    $language='RU'
    if ($Request.PSObject.Properties['language']) {
        if ($Request.language -notin @('RU','EN')) { throw 'Invalid language.' }
        $language=[string]$Request.language
    }
    $ids=@()
    if ($Request.action -in @('install','uninstall')) {
        if (-not $Request.PSObject.Properties['ids']) { throw 'An app selection is required.' }
        $ids=@($Request.ids | Select-Object -Unique)
        $allowed=@((Get-DebloatCatalog).Id)
        if ($Request.action -eq 'install') { $allowed=@((Get-InstallCatalog).Id) }
        if (-not $ids.Count -or $ids.Count -gt 32 -or @($ids | Where-Object { $_ -isnot [string] -or $_ -notin $allowed }).Count) { throw 'Invalid app selection.' }
    }
    [pscustomobject]@{action=[string]$Request.action;ids=$ids;language=$language}
}

function Get-WebPlan($Request) {
    $validated=Test-WebAction $Request
    if ($validated.action -eq 'install') { return @(Get-AppInstallPlan $validated.ids | ForEach-Object { [pscustomobject]@{id=$_.Id;name=$_.Name;noteRU=$_.NoteRU;noteEN=$_.NoteEN;dependency=($_.Id -notin $validated.ids)} }) }
    if ($validated.action -eq 'uninstall') {
        $previous=$env:DEBLOAT_LANGUAGE; Set-UiLanguage $validated.language
        try { return @(Get-DebloatCatalog | Where-Object { $_.Id -in $validated.ids } | ForEach-Object { [pscustomobject]@{id=$_.Id;name=$_.Title;noteRU=$_.Note;noteEN=$_.Note;dependency=$false} }) }
        finally {$env:DEBLOAT_LANGUAGE=$previous}
    }
    return @()
}

function Read-WebRequest([IO.Stream]$Stream) {
    $header=New-Object 'System.Collections.Generic.List[byte]'
    while ($true) {
        $value=$Stream.ReadByte()
        if ($value -lt 0) { throw 'Incomplete HTTP headers.' }
        $header.Add([byte]$value)
        if ($header.Count -gt 16384) { throw 'HTTP headers are too large.' }
        $n=$header.Count
        if ($n -ge 4 -and $header[$n-4] -eq 13 -and $header[$n-3] -eq 10 -and $header[$n-2] -eq 13 -and $header[$n-1] -eq 10) { break }
    }
    $lines=[Text.Encoding]::ASCII.GetString($header.ToArray()) -split "`r`n"
    if ($lines[0] -notmatch '^(GET|POST) (/[^\s]*) HTTP/1\.[01]$') { throw 'Unsupported HTTP request.' }
    $method=$Matches[1];$path=$Matches[2]
    $headers=@{}
    foreach ($line in $lines[1..($lines.Count-1)]) {
        if (-not $line) {continue}
        $parts=$line -split ':',2
        if ($parts.Count -ne 2 -or $headers.ContainsKey($parts[0].ToLowerInvariant())) { throw 'Invalid or duplicate HTTP header.' }
        $headers[$parts[0].ToLowerInvariant()]=$parts[1].Trim()
    }
    if ($headers.ContainsKey('transfer-encoding')) { throw 'Transfer encoding is not supported.' }
    $length=0
    if ($headers.ContainsKey('content-length') -and (-not [int]::TryParse($headers['content-length'],[ref]$length) -or $length -lt 0 -or $length -gt 65536)) { throw 'Invalid request length.' }
    $body=[byte[]]::new($length);$offset=0
    while ($offset -lt $length) { $read=$Stream.Read($body,$offset,$length-$offset); if ($read -le 0) {throw 'Incomplete request body.'}; $offset+=$read }
    [pscustomobject]@{method=$method;path=$path;headers=$headers;body=[Text.Encoding]::UTF8.GetString($body)}
}

function Send-WebResponse([IO.Stream]$Stream,[int]$Status,[string]$ContentType,[byte[]]$Bytes) {
    $reason=@{200='OK';202='Accepted';400='Bad Request';403='Forbidden';404='Not Found';409='Conflict';500='Internal Server Error'}[$Status]
    $headers="HTTP/1.1 $Status $reason`r`nContent-Type: $ContentType`r`nContent-Length: $($Bytes.Length)`r`nConnection: close`r`nCache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nReferrer-Policy: no-referrer`r`nContent-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`r`n`r`n"
    $head=[Text.Encoding]::ASCII.GetBytes($headers)
    $Stream.Write($head,0,$head.Length);$Stream.Write($Bytes,0,$Bytes.Length);$Stream.Flush()
}
