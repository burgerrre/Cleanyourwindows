#requires -Version 5.1
# All OS inventory and feature removal commands are mocked.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Defender.Tools.ps1')
& {
    $script:fixtureBuild = '19045'
    $script:fixtureType = 1
    $script:fixtureEdition = 'Professional'
    function Get-CimInstance { param($ClassName,$ErrorAction) [pscustomobject]@{ ProductType=$script:fixtureType; BuildNumber=$script:fixtureBuild; Caption='Test Windows' } }
    function Get-ItemProperty { param($LiteralPath,$ErrorAction) [pscustomobject]@{ EditionID=$script:fixtureEdition } }
    function Get-Command { param($Name,$ErrorAction) [pscustomobject]@{ Name=$Name } }
    foreach ($case in @(
        @('19045',1,'Professional','Windows 10',$false,$false),
        @('26100',1,'Professional','Windows 11',$false,$false),
        @('19044',1,'EnterpriseS','Windows 10',$true,$false),
        @('26100',1,'IoTEnterpriseS','Windows 11',$true,$false),
        @('20348',3,'ServerStandard','Windows Server',$false,$true),
        @('14393',2,'ServerDatacenter','Windows Server',$false,$true),
        @('9600',3,'ServerStandard','Windows Server',$false,$false)
    )) {
        $script:fixtureBuild=$case[0]; $script:fixtureType=$case[1]; $script:fixtureEdition=$case[2]
        $p = Get-DefenderPlatform
        if ($p.Family -ne $case[3] -or $p.LTSC -ne $case[4] -or $p.Supported -ne $case[5]) { throw "OS detection failed: $($case -join ',')" }
    }
    $script:fixtureType=1
    $blocked=$false
    try { Invoke-DefenderFeatureRemoval | Out-Null } catch { $blocked=$true }
    if (-not $blocked) { throw 'Client Windows removal was not blocked.' }
    $script:fixtureType=3; $script:fixtureBuild='20348'
    $script:installed=$true; $script:removeCalls=0; $script:restart='No'
    function Get-WindowsFeature { param($Name,$ErrorAction) [pscustomobject]@{ Name='Windows-Defender'; Installed=$script:installed } }
    function Uninstall-WindowsFeature {
        param($Name,[switch]$Remove,[switch]$Restart,$ErrorAction)
        if ($Restart -or -not $Remove -or $Name -notcontains 'Windows-Defender') { throw 'Incorrect removal arguments.' }
        $script:removeCalls++; $script:installed=$false
        [pscustomobject]@{ Success=$true; RestartNeeded=$script:restart; ExitCode='Success' }
    }
    Invoke-DefenderFeatureRemoval -WhatIf | Out-Null
    if ($script:removeCalls) { throw 'WhatIf removed a feature.' }
    $r=Invoke-DefenderFeatureRemoval -Confirm:$false
    if ($r.Status -ne 'Removed' -or $script:removeCalls -ne 1) { throw 'Removal verification failed.' }
    $r=Invoke-DefenderFeatureRemoval -Confirm:$false
    if ($r.Status -ne 'NotInstalled' -or $script:removeCalls -ne 1) { throw 'Absent feature was removed again.' }
    $script:installed=$true; $script:restart='Yes'
    $r=Invoke-DefenderFeatureRemoval -Confirm:$false
    if ($r.Status -ne 'PendingRestart' -or -not $r.RestartRequired) { throw 'Restart status was lost.' }
}
Write-Host 'PASS: 7 OS fixtures, client guard, WhatIf, removal, absent feature and pending restart (all mocked).' -ForegroundColor Green
