#requires -Version 5.1
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Debloat.Menu.ps1')
$fixtureParent=Join-Path $PSScriptRoot '.test-artifacts'
$fixtureRoot=Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
try {
    & {
        $script:bootstrapCalls=0; $script:wingetReady=$false
        function Get-AppWingetPath { if ($script:wingetReady) { 'mock-winget.exe' } }
        function Install-AppWinget { param($ErrorAction) $script:bootstrapCalls++; $script:wingetReady=$true }
        function Invoke-AppWinget { param($Arguments) if ($Arguments[0] -ne '--version') { throw 'Unexpected native call.' }; [pscustomobject]@{ExitCode=0;Output='fixture version'} }
        function Test-AppWingetInstalled { param($App) $true }
        $items=@(Invoke-AppInstallation -Ids @('firefox','vlc') -ReportDirectory (Join-Path $fixtureRoot 'automatic'))
        if ($script:bootstrapCalls -ne 1 -or $items.Count -ne 2 -or @($items | Where-Object Status -ne 'AlreadyInstalled').Count) { throw 'Missing WinGet was not bootstrapped once before the batch.' }
        Invoke-AppInstallation -Ids @('firefox') -ReportDirectory (Join-Path $fixtureRoot 'existing') | Out-Null
        if ($script:bootstrapCalls -ne 1) { throw 'Existing WinGet was installed again.' }
    }
    & {
        $script:bootstrapCalls=0
        function Get-AppWingetPath { $null }
        function Install-AppWinget { param($ErrorAction) $script:bootstrapCalls++; throw 'fixture bootstrap failure' }
        function Invoke-AppWinget { throw 'WinGet must not run after bootstrap failure.' }
        function Test-AppWingetInstalled { throw 'Installed-app detection must not run after bootstrap failure.' }
        $script:githubCalls=0
        function Get-AppReleaseAsset { param($App) $script:githubCalls++; throw 'fixture GitHub download' }
        $items=@(Invoke-AppInstallation -Ids @('firefox','vlc','tgwsproxy') -ReportDirectory (Join-Path $fixtureRoot 'failed'))
        if ($script:bootstrapCalls -ne 1 -or $script:githubCalls -ne 1 -or $items.Count -ne 3) { throw 'Bootstrap was retried or unrelated GitHub installs were blocked.' }
        if ($items[0].Detail -notmatch 'fixture bootstrap failure' -or $items[1].Detail -notmatch 'fixture bootstrap failure') { throw 'Bootstrap error was lost from per-app reports.' }
    }
    & {
        $script:bootstrapCalls=0
        function Get-AppWingetPath { $null }
        function Install-AppWinget { $script:bootstrapCalls++; throw 'Unexpected bootstrap.' }
        function Get-AppReleaseAsset { param($App) throw 'fixture portable-only download' }
        Invoke-AppInstallation -Ids @('tgwsproxy') -ReportDirectory (Join-Path $fixtureRoot 'portable') | Out-Null
        if ($script:bootstrapCalls) { throw 'A portable-only selection installed WinGet.' }
        Invoke-AppInstallation -Ids @('firefox') -ReportDirectory (Join-Path $fixtureRoot 'whatif') -WhatIf | Out-Null
        if ($script:bootstrapCalls -or (Test-Path (Join-Path $fixtureRoot 'whatif'))) { throw 'WhatIf bootstrapped WinGet or wrote a report.' }
    }
    Write-Host 'PASS: automatic WinGet bootstrap, one attempt per batch, reuse, failure reporting, independent downloads and WhatIf (mocked).' -ForegroundColor Green
} finally {
    $resolved=[IO.Path]::GetFullPath($fixtureRoot)
    $prefix=[IO.Path]::GetFullPath($fixtureParent).TrimEnd('\')+'\'
    if (-not $resolved.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
