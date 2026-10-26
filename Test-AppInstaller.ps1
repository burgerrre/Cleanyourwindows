#requires -Version 5.1
# Native installers, network downloads and shortcuts are mocked in these checks.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Debloat.Menu.ps1')
# The generic installer tests must never bootstrap software on the test host.
function Get-AppWingetPath { 'mock-winget.exe' }
function Install-AppWinget { throw 'Unexpected real WinGet bootstrap in installer tests.' }
$fixtureParent=Join-Path $PSScriptRoot '.test-artifacts'
$fixtureRoot=Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
$previousLanguage=$env:DEBLOAT_LANGUAGE
try {
    $catalog=@(Get-InstallCatalog)
    if ($catalog.Count -ne 16 -or @($catalog.Id | Select-Object -Unique).Count -ne 16) { throw 'Application catalog is incomplete or has duplicate IDs.' }
    if ((@(Get-AppInstallPlan @('vencord','discord','firefox')).Id -join ',') -ne 'discord,vencord,firefox') { throw 'Dependencies are not ordered or deduplicated.' }
    $rejected=$false
    try { Get-AppInstallPlan @('not-in-catalog') | Out-Null } catch { $rejected=$true }
    if (-not $rejected) { throw 'Unknown application accepted.' }

    & {
        Set-UiLanguage EN
        $script:installCalls=0
        $script:menuOutput=New-Object 'System.Collections.Generic.List[string]'
        $queue=New-Object 'System.Collections.Generic.Queue[string]'
        foreach ($line in @('7','P','','I','n','Q')) { $queue.Enqueue($line) }
        function Read-Host { param($Prompt) if (-not $queue.Count) { throw 'Unexpected installer menu input.' }; $script:menuOutput.Add($Prompt); $queue.Dequeue() }
        function Write-Host { param($Object,$ForegroundColor,$NoNewline) $script:menuOutput.Add([string]$Object) }
        function Clear-Host { }
        function Get-AppWingetPath { 'mock-winget.exe' }
        function Invoke-AppInstallation { param($Ids) $script:installCalls++ }
        Show-AppInstallMenu
        if ($script:installCalls -or $queue.Count) { throw 'Preview/cancellation launched an installer.' }
        if (($script:menuOutput -join ' ') -match '[А-Яа-яЁё]') { throw 'English installation menu contains Russian.' }
        foreach ($line in @('7','I',' Y ','','Q')) { $queue.Enqueue($line) }
        Show-AppInstallMenu
        if ($script:installCalls -ne 1 -or $queue.Count) { throw 'y confirmation did not launch one batch.' }
    }

    & {
        $app=$catalog | Where-Object Id -eq 'tgwsproxy'
        $script:releaseFixture=[pscustomobject]@{
            tag_name='v1.0';draft=$false;prerelease=$false
            assets=@(
                [pscustomobject]@{name='TgWsProxy_linux_amd64';browser_download_url='https://github.com/Flowseal/tg-ws-proxy/releases/download/v1.0/linux';digest=('sha256:'+('a'*64));size=1},
                [pscustomobject]@{name='TgWsProxy_windows.exe';browser_download_url='https://github.com/Flowseal/tg-ws-proxy/releases/download/v1.0/TgWsProxy_windows.exe';digest=('sha256:'+('b'*64));size=1},
                [pscustomobject]@{name='TgWsProxy_windows_arm64.exe';browser_download_url='https://github.com/Flowseal/tg-ws-proxy/releases/download/v1.0/TgWsProxy_windows_arm64.exe';digest=('sha256:'+('c'*64));size=1}
            )
        }
        $script:testArchitecture='x64'
        function Invoke-RestMethod { param($Uri,$Headers,$ErrorAction) $script:releaseFixture }
        function Get-AppArchitecture { $script:testArchitecture }
        if ((Get-AppReleaseAsset $app).Name -ne 'TgWsProxy_windows.exe') { throw 'Wrong x64 asset.' }
        $script:testArchitecture='arm64'
        if ((Get-AppReleaseAsset $app).Name -ne 'TgWsProxy_windows_arm64.exe') { throw 'Wrong ARM64 asset.' }
        $script:testArchitecture='x64'
        $script:releaseFixture.assets[1].browser_download_url='https://example.com/untrusted.exe'
        $rejected=$false
        try { Get-AppReleaseAsset $app | Out-Null } catch { $rejected=$true }
        if (-not $rejected) { throw 'Off-repository download was accepted.' }
        $script:releaseFixture.assets[1].browser_download_url='https://github.com/Flowseal/tg-ws-proxy/releases/download/v1.0/TgWsProxy_windows.exe'
        $script:releaseFixture.assets[1].digest=''
        $rejected=$false
        try { Get-AppReleaseAsset $app | Out-Null } catch { $rejected=$true }
        if (-not $rejected) { throw 'Missing release checksum was accepted.' }
    }

    & {
        $script:downloadText='Verified installer fixture; never executable'
        function Invoke-WebRequest { param($Uri,[switch]$UseBasicParsing,$OutFile,$ErrorAction) [IO.File]::WriteAllText($OutFile,$script:downloadText,[Text.UTF8Encoding]::new($false)) }
        $bytes=[Text.Encoding]::UTF8.GetBytes($script:downloadText)
        $sha=[Security.Cryptography.SHA256]::Create()
        try { $digest=[BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','') } finally { $sha.Dispose() }
        $asset=[pscustomobject]@{Name='fixture.exe';Url='https://github.com/example/fixture';Size=$bytes.Length;SHA256=$digest}
        $saved=Save-AppReleaseAsset $asset (Join-Path $fixtureRoot 'download-good')
        if (-not (Test-Path -LiteralPath $saved)) { throw 'Verified download was not saved.' }
        $asset.SHA256='0'*64
        $rejected=$false
        try { Save-AppReleaseAsset $asset (Join-Path $fixtureRoot 'download-bad') | Out-Null } catch { $rejected=$true }
        if (-not $rejected) { throw 'Corrupt download was accepted.' }
    }

    Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem
    foreach ($case in @(@('safe','service.bat'),@('unsafe','../outside.ps1'))) {
        $path=Join-Path $fixtureRoot ($case[0]+'.zip')
        $zip=[IO.Compression.ZipFile]::Open($path,[IO.Compression.ZipArchiveMode]::Create)
        try { $entry=$zip.CreateEntry($case[1]); $writer=[IO.StreamWriter]::new($entry.Open()); try {$writer.Write('fixture only')} finally {$writer.Dispose()} } finally {$zip.Dispose()}
        $destination=Join-Path $fixtureRoot ($case[0]+'-expanded')
        if ($case[0] -eq 'safe') { Expand-AppArchive $path $destination; if (-not (Test-Path (Join-Path $destination 'service.bat'))) { throw 'Safe extraction failed.' } }
        else {
            $rejected=$false
            try { Expand-AppArchive $path $destination } catch { $rejected=$true }
            if (-not $rejected -or (Test-Path $destination) -or (Test-Path (Join-Path $fixtureRoot 'outside.ps1'))) { throw 'Archive traversal was not rejected before writes.' }
        }
    }

    & {
        $script:nativeCalls=0; $script:listCalls=0
        function Start-Process { throw 'Real installer invocation is forbidden in this test.' }
        function Invoke-AppWinget {
            param($Arguments)
            $script:nativeCalls++
            if ($Arguments[0] -eq 'list') {
                $script:listCalls++
                return [pscustomobject]@{ExitCode=$(if ($script:listCalls -eq 1) {1} else {0});Output='fixture'}
            }
            if ($Arguments -notcontains '--silent' -or $Arguments -notcontains 'Mozilla.Firefox' -or $Arguments -notcontains '--exact') { throw 'Incorrect WinGet install arguments.' }
            [pscustomobject]@{ExitCode=0;Output='mock install'}
        }
        Invoke-AppInstallation -Ids @('firefox') -ReportDirectory (Join-Path $fixtureRoot 'whatif') -WhatIf | Out-Null
        if ($script:nativeCalls -or (Test-Path (Join-Path $fixtureRoot 'whatif'))) { throw 'WhatIf had side effects.' }
        $result=@(Invoke-AppInstallation -Ids @('firefox') -ReportDirectory (Join-Path $fixtureRoot 'winget'))
        if ($result[0].Status -ne 'Installed' -or $script:nativeCalls -ne 3) { throw 'WinGet installation was not verified.' }
        $result=@(Invoke-AppInstallation -Ids @('firefox') -ReportDirectory (Join-Path $fixtureRoot 'winget'))
        if ($result[0].Status -ne 'AlreadyInstalled' -or $script:nativeCalls -ne 4) { throw 'Existing application was reinstalled.' }
    }

    & {
        $script:githubCalls=0
        function Invoke-AppWinget { param($Arguments) [pscustomobject]@{ExitCode=5;Output='mock failure'} }
        function Get-AppReleaseAsset { param($App) $script:githubCalls++; throw 'Dependency failure should have prevented this.' }
        $result=@(Invoke-AppInstallation -Ids @('vencord') -ReportDirectory (Join-Path $fixtureRoot 'dependency'))
        if ($result.Count -ne 2 -or $result[0].Status -ne 'Failed' -or $result[1].Status -ne 'BlockedDependency' -or $script:githubCalls) { throw 'Failed Discord dependency did not block Vencord.' }
    }
    & {
        $script:shortcutCalls=0
        $script:setupCalls=New-Object 'System.Collections.Generic.List[string]'
        function Test-AppWingetInstalled { param($App) $true }
        function Get-AppReleaseAsset {
            param($App)
            [pscustomobject]@{Version='fixture';Name='fixture.exe';Url='https://github.com/'+$App.Repository+'/releases/download/fixture/fixture.exe';SHA256=('a'*64);Size=1}
        }
        function Save-AppReleaseAsset { param($Asset,$Directory) Join-Path $fixtureRoot 'fixture.exe' }
        function Expand-AppArchive { param($Archive,$Destination) }
        function Get-ChildItem { param($LiteralPath,$Filter,[switch]$File,[switch]$Recurse) [pscustomobject]@{FullName=(Join-Path $fixtureRoot 'service.bat');DirectoryName=$fixtureRoot} }
        function New-AppStartShortcut { param($Name,$Target,$WorkingDirectory,$Arguments) $script:shortcutCalls++ }
        function Invoke-AppSetup { param($File,$Arguments=@()) $script:setupCalls.Add(($Arguments -join ' ')); 0 }
        $result=@(Invoke-AppInstallation -Ids @('tgwsproxy','zapret','happ','vencord') -ReportDirectory (Join-Path $fixtureRoot 'providers'))
        if ($result.Count -ne 5 -or @($result | Where-Object Status -eq 'PortableReady').Count -ne 2) { throw 'Portable installation providers failed.' }
        if (($result | Where-Object Id -eq 'happ').Status -ne 'NeedsSetup') { throw 'Happ wizard was incorrectly reported as a verified install.' }
        if (($result | Where-Object Id -eq 'vencord').Status -ne 'Installed' -or $script:setupCalls -notcontains '-install -branch stable') { throw 'Vencord CLI arguments were incorrect.' }
        if ($script:shortcutCalls -ne 2) { throw 'Portable shortcuts were not created.' }
    }
    Write-Host 'PASS: installer selection, dependencies, RU/EN, asset/architecture selection, URL/hash checks, ZIP traversal, WhatIf and all mocked installer providers.' -ForegroundColor Green
} finally {
    $env:DEBLOAT_LANGUAGE=$previousLanguage
    $resolved=[IO.Path]::GetFullPath($fixtureRoot)
    $prefix=[IO.Path]::GetFullPath($fixtureParent).TrimEnd('\')+'\'
    if (-not $resolved.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup path escaped its test directory.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction Stop
}
