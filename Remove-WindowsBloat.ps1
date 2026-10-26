#requires -Version 5.1
<#
.SYNOPSIS
Preview or uninstall Microsoft Edge, Microsoft 365, Copilot and selected inbox apps.
.EXAMPLE
.\Remove-WindowsBloat.ps1
.EXAMPLE
.\Remove-WindowsBloat.ps1 -Apply -IncludeExtras
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch]$Apply,
    [switch]$Preview,
    [switch]$IncludeExtras,
    [switch]$KeepEdge,
    [switch]$KeepOffice,
    [switch]$KeepCopilot,
    [string]$ReportDirectory = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Debloat.Menu.ps1')
$script:Results = New-Object 'System.Collections.Generic.List[object]'
$script:RebootRequired = $false
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Run Windows PowerShell as administrator (including preview, to inventory all users).' }

$catalog = @(Get-DebloatCatalog | Where-Object {
    -not (($KeepCopilot -and $_.Id -eq 'copilot') -or
          ($KeepOffice -and $_.Id -eq 'office') -or ($KeepEdge -and $_.Id -eq 'edge'))
})
$selectedIds = @($catalog.Id)

function Add-Result([string]$Target, [string]$Action, [string]$Status, [string]$Detail) {
    $script:Results.Add([pscustomobject]@{
        Target = $Target; Action = $Action; Status = $Status; Detail = $Detail
    })
    Write-Host "[$Status] $Action : $Target $Detail"
}

function Get-RegisteredTargets {
    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($root in $roots) {
        foreach ($entry in @(Get-ItemProperty -Path $root -ErrorAction SilentlyContinue)) {
            if (-not $entry.PSObject.Properties['DisplayName']) { continue }
            $display = [string]$entry.DisplayName
            $edge = ('edge' -in $selectedIds) -and ($display -eq 'Microsoft Edge')
            $office = ('office' -in $selectedIds) -and ($display -match '^Microsoft 365(?:\s|$)')
            $copilot = ('copilot' -in $selectedIds) -and ($display -in @('Microsoft Copilot', 'Copilot'))
            if ($edge -or $office -or $copilot) { $entry }
        }
    }
}

function Split-UninstallCommand([string]$Command) {
    # Parse an executable path; never execute registry strings via cmd/Invoke-Expression.
    if ($Command -match '^\s*"([^"\r\n]+\.exe)"\s*(.*)$') {
        return [pscustomobject]@{ File = $matches[1]; Arguments = $matches[2] }
    }
    if ($Command -match '^\s*(.+?\.exe)(?:\s+(.*))?$') {
        $arguments = ''
        if ($matches.ContainsKey(2)) { $arguments = $matches[2] }
        return [pscustomobject]@{ File = $matches[1]; Arguments = $arguments }
    }
    throw 'Unsupported uninstall command. Use Settings > Apps for this entry.'
}

function Invoke-RegisteredUninstall($Entry) {
    $command = ''
    foreach ($property in @('UninstallString', 'QuietUninstallString')) {
        if ($Entry.PSObject.Properties[$property] -and $Entry.$property) {
            $command = [Environment]::ExpandEnvironmentVariables([string]$Entry.$property)
            break
        }
    }
    if (-not $command) { throw 'No registered uninstaller found.' }
    $parsed = Split-UninstallCommand $command
    $leaf = [IO.Path]::GetFileName($parsed.File)
    if ($leaf -ieq 'msiexec.exe') {
        if ($parsed.Arguments -notmatch '\{[0-9A-Fa-f-]{36}\}') { throw 'Missing MSI product identifier.' }
        $product = $matches[0]
        $parsed.File = Join-Path $env:SystemRoot 'System32\msiexec.exe'
        $parsed.Arguments = "/x $product /passive /norestart"
    } else {
        if (-not [IO.Path]::IsPathRooted($parsed.File)) { throw 'Uninstaller path must be absolute.' }
        if (-not (Test-Path -LiteralPath $parsed.File -PathType Leaf)) { throw 'Uninstaller file is missing.' }
        $signature = Get-AuthenticodeSignature -LiteralPath $parsed.File
        if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)') {
            throw 'Uninstaller does not have a valid Microsoft signature.'
        }
        # Some Edge editions reject this. Verification below reports remaining installations.
        if ($Entry.DisplayName -eq 'Microsoft Edge') {
            $parsed.Arguments += ' --force-uninstall'
        }
    }
    $start = @{ FilePath = $parsed.File; Wait = $true; PassThru = $true }
    if ($parsed.Arguments) { $start.ArgumentList = $parsed.Arguments }
    $process = Start-Process @start
    if ($process.ExitCode -in @(1641, 3010)) { $script:RebootRequired = $true }
    if ($process.ExitCode -notin @(0, 1641, 3010)) { throw "Uninstaller exit code: $($process.ExitCode)" }
    Add-Result $Entry.DisplayName 'Uninstaller' 'StartedAndExited' "Exit code $($process.ExitCode); inventory verification follows."
}

$before = [IO.DriveInfo]::new($env:SystemDrive + '\').AvailableFreeSpace
Show-DebloatBanner
Write-Host '  Сканирование установленных приложений...' -ForegroundColor Cyan
$allInstalled = @(Get-AppxPackage -AllUsers)
$allProvisioned = @(Get-AppxProvisionedPackage -Online)
$allRegistered = @(Get-RegisteredTargets)
if (-not $Apply -and -not $Preview -and -not $WhatIfPreference) {
    $presentIds = @(foreach ($item in $catalog) {
        $found = @($allInstalled | Where-Object { $_.Name -in $item.Packages }).Count -gt 0
        $found = $found -or (@($allProvisioned | Where-Object { $_.DisplayName -in $item.Packages }).Count -gt 0)
        foreach ($entry in $allRegistered) {
            if (($item.Id -eq 'edge' -and $entry.DisplayName -eq 'Microsoft Edge') -or
                ($item.Id -eq 'office' -and $entry.DisplayName -match '^Microsoft 365(?:\s|$)') -or
                ($item.Id -eq 'copilot' -and $entry.DisplayName -in @('Microsoft Copilot','Copilot'))) { $found = $true }
        }
        if ($found) { $item.Id }
    })
    $selection = Show-DebloatMenu -Catalog $catalog -PresentIds $presentIds
    if ($null -eq $selection) { Write-Host '  Выход. Ничего не удалено.' -ForegroundColor Cyan; return }
    $selectedIds = @($selection.Ids)
    $Apply = [switch]$true
} else {
    $selectedIds = @($catalog | Where-Object { $IncludeExtras -or $_.Id -in @('edge','office','copilot') } | Select-Object -ExpandProperty Id)
}
$names = @($catalog | Where-Object { $_.Id -in $selectedIds } | ForEach-Object { $_.Packages })
$installed = @($allInstalled | Where-Object { $_.Name -in $names })
$provisioned = @($allProvisioned | Where-Object { $_.DisplayName -in $names })
$registered = @(Get-RegisteredTargets | Sort-Object -Property PSPath -Unique)

Write-Host ('Selected groups: ' + ($selectedIds -join ', ')) -ForegroundColor Cyan
Write-Host 'Office removal includes Word/Excel/PowerPoint in the Microsoft 365 suite. Close these apps first.'
Write-Host 'Store, Defender, Windows Update, WebView2, drivers and personal files are outside the target list.'
if (-not $Apply) { Write-Host 'PREVIEW ONLY. Add -Apply to uninstall. You can also combine -Apply with -WhatIf.' }

foreach ($package in $installed) {
    $target = $package.PackageFullName
    if (-not $Apply) { Add-Result $target 'RemoveAppxAllUsers' 'Planned' ''; continue }
    if ($PSCmdlet.ShouldProcess($target, 'Remove app package for all users')) {
        try {
            if ($package.NonRemovable) { throw 'Windows marks this package as non-removable.' }
            Remove-AppxPackage -Package $target -AllUsers -ErrorAction Stop
            Add-Result $target 'RemoveAppxAllUsers' 'CommandSucceeded' ''
        } catch { Add-Result $target 'RemoveAppxAllUsers' 'Failed' $_.Exception.Message }
    }
}
foreach ($package in $provisioned) {
    $target = $package.PackageName
    if (-not $Apply) { Add-Result $target 'RemoveProvisioning' 'Planned' ''; continue }
    if ($PSCmdlet.ShouldProcess($target, 'Remove provisioned app for future user accounts')) {
        try {
            $result = Remove-AppxProvisionedPackage -Online -PackageName $target -AllUsers -ErrorAction Stop
            if ($result.RestartNeeded) { $script:RebootRequired = $true }
            Add-Result $target 'RemoveProvisioning' 'CommandSucceeded' ''
        } catch { Add-Result $target 'RemoveProvisioning' 'Failed' $_.Exception.Message }
    }
}
foreach ($entry in $registered) {
    if (-not $Apply) { Add-Result $entry.DisplayName 'Uninstaller' 'Planned' $entry.PSPath; continue }
    if ($PSCmdlet.ShouldProcess($entry.DisplayName, 'Run registered Microsoft uninstaller (may display a window)')) {
        try { Invoke-RegisteredUninstall $entry }
        catch { Add-Result $entry.DisplayName 'Uninstaller' 'Failed' $_.Exception.Message }
    }
}

# Inspect actual state after uninstallers. A successful exit alone is not proof of removal.
$remainingAppx = @(Get-AppxPackage -AllUsers | Where-Object { $_.Name -in $names } | Select-Object -ExpandProperty PackageFullName)
$remainingProvisioned = @(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -in $names } | Select-Object -ExpandProperty PackageName)
$remainingDesktop = @(Get-RegisteredTargets | Select-Object -ExpandProperty DisplayName)
$after = [IO.DriveInfo]::new($env:SystemDrive + '\').AvailableFreeSpace
$report = [ordered]@{
    Date = (Get-Date).ToString('o'); Apply = [bool]$Apply; WhatIf = [bool]$WhatIfPreference
    Computer = $env:COMPUTERNAME; SelectedGroups = $selectedIds; TargetPackageNames = $names; Results = @($script:Results.ToArray())
    RemainingAppx = $remainingAppx; RemainingProvisioned = $remainingProvisioned
    RemainingDesktop = $remainingDesktop; RebootRequired = $script:RebootRequired
    SystemDriveFreeBytesBefore = $before; SystemDriveFreeBytesAfter = $after
    ObservedFreeSpaceDeltaBytes = ($after - $before)
}
# Report files are the only writes during preview; WhatIf suppresses these too.
if (-not $WhatIfPreference) {
    if (-not (Test-Path -LiteralPath $ReportDirectory -PathType Container)) {
        New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
    }
    $reportPath = Join-Path $ReportDirectory ('debloat-report-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.json')
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Host "Report: $reportPath"
}
Write-Host ('Observed free-space change: {0:N2} GiB (other system activity can affect this).' -f (($after - $before) / 1GB))
if ($Apply -and -not $WhatIfPreference) {
    $remainingCount = $remainingAppx.Count + $remainingProvisioned.Count + $remainingDesktop.Count
    Write-Host "Remaining target inventory entries: $remainingCount. Check the JSON report."
    Write-Host 'Windows updates can reinstall inbox applications. App profiles and user documents were preserved.'
    Write-Host 'If Edge remains, Windows may block its removal. WebView2 is a separate shared runtime.'
    Write-Host "Reboot requested by uninstallers: $script:RebootRequired"
}
