. (Join-Path $PSScriptRoot 'Localization.ps1')
$script:InstallStrings=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Install.Strings.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function Get-InstallText([string]$Key, [object[]]$Values=@()) {
    $language='RU'
    if ($env:DEBLOAT_LANGUAGE -eq 'EN') { $language='EN' }
    $text=[string]$script:InstallStrings.$Key.$language
    if ($Values.Count) { return $text -f $Values }
    return $text
}

function Get-InstallCatalog {
    $catalog=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Install.Catalog.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($app in $catalog) { $app }
}

function Get-AppInstallPlan([string[]]$Ids) {
    $catalog=@(Get-InstallCatalog)
    $seen=@{}; $active=@{}
    $plan=New-Object 'System.Collections.Generic.List[object]'
    function Add-InstallDependency([string]$Id) {
        if ($seen.ContainsKey($Id)) { return }
        if ($active.ContainsKey($Id)) { throw "Circular application dependency: $Id" }
        $entries=@($catalog | Where-Object Id -eq $Id)
        if ($entries.Count -ne 1) { throw "Unknown or duplicate application ID: $Id" }
        $active[$Id]=$true
        foreach ($dependency in $entries[0].Dependencies) { Add-InstallDependency $dependency }
        $active.Remove($Id)
        $seen[$Id]=$true
        $plan.Add($entries[0])
    }
    foreach ($id in $Ids) { Add-InstallDependency $id }
    return $plan.ToArray()
}

function Get-AppWingetPath {
    $command=Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $alias=Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path -LiteralPath $alias) { return $alias }
    return $null
}

function Install-AppWinget {
    [CmdletBinding(SupportsShouldProcess=$true)]param()
    if (-not $PSCmdlet.ShouldProcess('Microsoft.WinGet.Client / WinGet','Install or repair from Microsoft sources')) { return }
    [Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -Scope CurrentUser -Force -ErrorAction Stop | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Scope CurrentUser -Force -ErrorAction Stop | Out-Null
    Import-Module Microsoft.WinGet.Client -ErrorAction Stop
    Repair-WinGetPackageManager -AllUsers -ErrorAction Stop | Out-Null
    if (-not (Get-AppWingetPath)) { throw (Get-InstallText NeedWinget) }
}

function Invoke-AppWinget([string[]]$Arguments) {
    $path=Get-AppWingetPath
    if (-not $path) { throw (Get-InstallText NeedWinget) }
    $previous=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        $output=& $path @Arguments 2>&1
        $code=$LASTEXITCODE
    } finally { $ErrorActionPreference=$previous }
    [pscustomobject]@{ ExitCode=[int]$code; Output=($output | Out-String).Trim() }
}

function Test-AppWingetInstalled($App) {
    $result=Invoke-AppWinget @('list','--id',$App.PackageId,'--exact','--source',$App.Source,'--accept-source-agreements','--disable-interactivity')
    return $result.ExitCode -eq 0
}

function Get-AppArchitecture {
    $arch=$env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432) { $arch=$env:PROCESSOR_ARCHITEW6432 }
    if ([Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE','Machine') -eq 'ARM64') { $arch='ARM64' }
    if ($arch -eq 'ARM64') { return 'arm64' }
    if ([Environment]::Is64BitOperatingSystem) { return 'x64' }
    return 'x86'
}

function Get-AppReleaseAsset($App) {
    if ($App.Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw 'Invalid repository identifier.' }
    $release=Invoke-RestMethod -Uri ('https://api.github.com/repos/'+$App.Repository+'/releases/latest') -Headers @{Accept='application/vnd.github+json';'User-Agent'='Cleanyourwindows'} -ErrorAction Stop
    if ($release.draft -or $release.prerelease) { throw 'Expected a stable public release.' }
    if ($App.Provider -eq 'GitHubZip') { $assets=@($release.assets | Where-Object name -match $App.AssetPattern) }
    else {
        $architecture=Get-AppArchitecture
        if ($architecture -eq 'x86') { throw (Get-InstallText UnsupportedArchitecture) }
        $name=$App.AssetX64
        if ($architecture -eq 'arm64') { $name=$App.AssetArm64 }
        $assets=@($release.assets | Where-Object name -eq $name)
    }
    if ($assets.Count -ne 1) { throw (Get-InstallText AssetsChanged) }
    $asset=$assets[0]
    $uri=[uri]$asset.browser_download_url
    $prefix='/'+$App.Repository+'/releases/download/'
    if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'github.com' -or -not $uri.AbsolutePath.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw (Get-InstallText UnsafeUrl) }
    if (-not $asset.PSObject.Properties['digest'] -or $asset.digest -notmatch '^sha256:[a-fA-F0-9]{64}$') { throw (Get-InstallText MissingDigest) }
    [pscustomobject]@{ Version=[string]$release.tag_name; Name=[string]$asset.name; Url=$uri.AbsoluteUri; SHA256=$asset.digest.Substring(7); Size=[long]$asset.size }
}

function Save-AppReleaseAsset($Asset, [string]$Directory) {
    if ([IO.Path]::GetFileName($Asset.Name) -ne $Asset.Name -or $Asset.Name -match '[<>:"/\\|?*]') { throw 'Invalid release asset filename.' }
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    # Portable apps must remain writable when launched without elevation.
    $permissions=Get-Acl -LiteralPath $Directory
    $user=[Security.Principal.WindowsIdentity]::GetCurrent().User
    $rule=[Security.AccessControl.FileSystemAccessRule]::new($user,[Security.AccessControl.FileSystemRights]::Modify,
        ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit),
        [Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow)
    $permissions.AddAccessRule($rule)
    Set-Acl -LiteralPath $Directory -AclObject $permissions
    $target=Join-Path $Directory $Asset.Name
    $part=$target+'.part'
    [Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $ProgressPreference='SilentlyContinue'
    Invoke-WebRequest -Uri $Asset.Url -UseBasicParsing -OutFile $part -ErrorAction Stop
    if ((Get-Item -LiteralPath $part).Length -ne $Asset.Size -or (Get-FileHash -LiteralPath $part -Algorithm SHA256).Hash -ne $Asset.SHA256) { throw (Get-InstallText BadDigest) }
    Move-Item -LiteralPath $part -Destination $target -Force
    return $target
}

function Expand-AppArchive([string]$Archive, [string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem
    $root=[IO.Path]::GetFullPath($Destination).TrimEnd('\')+'\'
    $zip=[IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $total=0L
        if ($zip.Entries.Count -gt 20000) { throw 'Archive contains too many files.' }
        # Validate every path and size before writing any archive entries.
        foreach ($entry in $zip.Entries) {
            $path=[IO.Path]::GetFullPath((Join-Path $root $entry.FullName))
            if (-not $path.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or $entry.FullName -match ':') { throw 'Unsafe archive entry.' }
            $total+=$entry.Length
            if ($total -gt 1GB) { throw 'Archive exceeds extraction limit.' }
        }
        if (Test-Path -LiteralPath $Destination) { throw 'Archive destination must be a new directory.' }
        New-Item -ItemType Directory -Path $Destination | Out-Null
        foreach ($entry in $zip.Entries) {
            $path=[IO.Path]::GetFullPath((Join-Path $root $entry.FullName))
            if (-not $entry.Name) { New-Item -ItemType Directory -Path $path -Force | Out-Null; continue }
            New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($path)) -Force | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$path,$false)
        }
    } finally { $zip.Dispose() }
}

function New-AppStartShortcut([string]$Name,[string]$Target,[string]$WorkingDirectory,[string]$Arguments='') {
    $folder=Join-Path ([Environment]::GetFolderPath('Programs')) 'Cleanyourwindows'
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $shell=New-Object -ComObject WScript.Shell
    $shortcut=$shell.CreateShortcut((Join-Path $folder ($Name+'.lnk')))
    $shortcut.TargetPath=$Target; $shortcut.WorkingDirectory=$WorkingDirectory; $shortcut.Arguments=$Arguments
    $shortcut.Save()
}

function Invoke-AppSetup([string]$File,[string[]]$Arguments=@()) {
    $parameters=@{FilePath=$File;Wait=$true;PassThru=$true;WorkingDirectory=[IO.Path]::GetDirectoryName($File)}
    if ($Arguments.Count) { $parameters.ArgumentList=$Arguments }
    $result=Start-Process @parameters
    if ($result.ExitCode -notin @(0,1641,3010)) { throw (Get-InstallText NativeExit @($result.ExitCode)) }
    return [int]$result.ExitCode
}

function Invoke-AppInstallation {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([string[]]$Ids,[string]$ReportDirectory=$PSScriptRoot)
    $plan=@(Get-AppInstallPlan $Ids)
    if (-not $PSCmdlet.ShouldProcess(($plan.Name -join ', '),'Install selected applications and dependencies')) { return }
    $results=New-Object 'System.Collections.Generic.List[object]'
    $states=@{}; $index=0
    foreach ($app in $plan) {
        $index++
        Write-Ui (Get-InstallText Installing @($index,$plan.Count,$app.Name)) -ForegroundColor Cyan
        $status='Failed'; $detail=''; $version=''; $location=''; $source=''; $checksum=''
        try {
            foreach ($dependency in $app.Dependencies) {
                if ($states[$dependency] -notin @('Installed','AlreadyInstalled','PortableReady')) {
                    $status='BlockedDependency'
                    throw (Get-InstallText BlockedDependency)
                }
            }
            if ($app.PSObject.Properties['MinBuild'] -and [Environment]::OSVersion.Version.Build -lt $app.MinBuild) { throw (Get-InstallText UnsupportedWindows) }
            if ($app.Provider -eq 'Winget') {
                $source=$app.Source+':'+$app.PackageId
                if (Test-AppWingetInstalled $app) { $status='AlreadyInstalled' }
                else {
                    $outcome=Invoke-AppWinget @('install','--id',$app.PackageId,'--exact','--source',$app.Source,'--silent','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
                    if ($outcome.Output) { Write-Host $outcome.Output }
                    if ($outcome.ExitCode -ne 0) { throw (Get-InstallText NativeExit @($outcome.ExitCode)) }
                    if (-not (Test-AppWingetInstalled $app)) { throw (Get-InstallText WingetUnverified) }
                    $status='Installed'
                }
            } else {
                $asset=Get-AppReleaseAsset $app
                $version=$asset.Version; $source=$asset.Url; $checksum=$asset.SHA256
                $base=Join-Path $env:ProgramData 'Cleanyourwindows\Apps'
                if ($app.Id -eq 'zapret' -and $base -match '[^\x20-\x7E]') { $base=Join-Path $env:SystemDrive 'CleanyourwindowsApps' }
                $safeVersion=$version -replace '[^a-zA-Z0-9_.-]','_'
                $location=Join-Path (Join-Path $base $app.Id) ($safeVersion+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
                $file=Save-AppReleaseAsset $asset $location
                switch ($app.Provider) {
                    'GitHubPortable' { New-AppStartShortcut $app.Name $file $location; $status='PortableReady' }
                    'GitHubZip' {
                        $extracted=Join-Path $location 'files'
                        Expand-AppArchive $file $extracted
                        $entry=Get-ChildItem -LiteralPath $extracted -Filter service.bat -File -Recurse | Sort-Object { $_.FullName.Length } | Select-Object -First 1
                        if (-not $entry) { throw 'zapret service.bat was not found in the release archive.' }
                        New-AppStartShortcut 'zapret - configure' $env:ComSpec $entry.DirectoryName ('/d /c ""{0}""' -f $entry.FullName)
                        $status='PortableReady'; $detail=Get-InstallText ZapretReady
                    }
                    'Vencord' { Invoke-AppSetup $file @('-install','-branch','stable') | Out-Null; $status='Installed' }
                    'GitHubSetup' { Invoke-AppSetup $file | Out-Null; $status='NeedsSetup' }
                    default { throw 'Unknown installer provider.' }
                }
            }
        } catch { $detail=$_.Exception.Message }
        $states[$app.Id]=$status
        $results.Add([pscustomobject]@{Id=$app.Id;Name=$app.Name;Status=$status;Detail=$detail;Version=$version;Source=$source;SHA256=$checksum;Location=$location})
        Write-Ui ('  '+(Get-InstallText $status)+' — '+$app.Name) -ForegroundColor $(if ($status -eq 'Failed') {'Yellow'} else {'Green'})
        if ($detail) { Write-Host ('  '+$detail) }
    }
    New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null
    $path=Join-Path $ReportDirectory ('install-report-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'.json')
    [ordered]@{Date=(Get-Date).ToString('o');Results=@($results.ToArray())} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $path -Encoding UTF8
    Write-Ui (Get-InstallText Report @($path)) -ForegroundColor Cyan
    return $results.ToArray()
}

function Show-AppInstallMenu {
    $catalog=@(Get-InstallCatalog); $selected=@{}; $message=''
    while ($true) {
        Clear-Host
        Write-Host '  WINDOWS DEBLOAT DELETOR' -ForegroundColor Cyan
        Write-Ui (Get-InstallText Title) -ForegroundColor Cyan
        Write-Ui (Get-InstallText Intro)
        $width=100
        try { $width=[Math]::Max(60,$Host.UI.RawUI.WindowSize.Width) } catch { }
        for ($i=0;$i -lt $catalog.Count;$i++) {
            $app=$catalog[$i]; $mark=' '
            if ($selected.ContainsKey($app.Id)) { $mark='X' }
            $note=$app.NoteRU
            if ($env:DEBLOAT_LANGUAGE -eq 'EN') { $note=$app.NoteEN }
            $limit=[Math]::Max(16,$width-39)
            if ($note.Length -gt $limit) { $note=$note.Substring(0,$limit-3)+'...' }
            Write-Host (' {0,2} [{1}] {2,-27} {3}' -f ($i+1),$mark,$app.Name,$note) -ForegroundColor $(if ($mark -eq 'X') {'Green'} else {'White'})
        }
        Write-Ui (Get-InstallText Selected @($selected.Count)) -ForegroundColor Cyan
        if (Get-AppWingetPath) { Write-Ui (Get-InstallText WingetReady) -ForegroundColor DarkGray }
        else { Write-Ui (Get-InstallText WingetMissing) -ForegroundColor Yellow }
        foreach ($key in @('Numbers','Actions','Run')) { Write-Ui (Get-InstallText $key) }
        if ($message) { Write-Host $message -ForegroundColor Yellow }
        $message=''
        $command=(Read-Ui (Get-InstallText Prompt)).Trim().ToUpperInvariant()
        switch ($command) {
            'Q' { return }
            'A' { foreach ($app in $catalog) { $selected[$app.Id]=$true }; continue }
            'N' { $selected.Clear(); continue }
            'B' {
                if ((Read-Ui (Get-InstallText BootstrapConfirm)).Trim() -ieq 'y') {
                    try { Install-AppWinget; $message=Get-InstallText BootstrapDone } catch { $message=$_.Exception.Message }
                }
                continue
            }
            {$_ -in @('I','P')} {
                if (-not $selected.Count) { $message=Get-InstallText Empty; continue }
                $ids=@($catalog | Where-Object {$selected.ContainsKey($_.Id)} | Select-Object -ExpandProperty Id)
                $plan=@(Get-AppInstallPlan $ids)
                Write-Ui (Get-InstallText Queue) -ForegroundColor Cyan
                foreach ($app in $plan) {
                    $note=$app.NoteRU
                    if ($env:DEBLOAT_LANGUAGE -eq 'EN') { $note=$app.NoteEN }
                    Write-Host ('  - '+$app.Name+': '+$note)
                }
                if ($command -eq 'P') { Read-Ui (Get-InstallText Back) | Out-Null; continue }
                Write-Ui (Get-InstallText Agreements) -ForegroundColor DarkGray
                if ('vencord' -in $ids) { Write-Ui (Get-InstallText CloseDiscord) -ForegroundColor Yellow }
                if ((Read-Ui (Get-InstallText Confirm)).Trim() -ieq 'y') {
                    try { Invoke-AppInstallation -Ids $ids | Out-Null; $selected.Clear(); Write-Ui (Get-InstallText Done) }
                    catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
                    Read-Ui (Get-InstallText Back) | Out-Null
                } else { $message=Get-InstallText Cancelled }
                continue
            }
            default {
                try {
                    foreach ($number in @(ConvertTo-DebloatNumbers $command $catalog.Count)) {
                        $id=$catalog[$number-1].Id
                        if ($selected.ContainsKey($id)) { $selected.Remove($id) } else { $selected[$id]=$true }
                    }
                } catch { $message=Get-UiText $_.Exception.Message }
            }
        }
    }
}
