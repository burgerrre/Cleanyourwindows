#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$Apply, [switch]$Worker, [string]$ReportPath, [ValidateSet('RU','EN')][string]$Language)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Localization.ps1')
if ($Language) { Set-UiLanguage $Language }
$vendor = Join-Path $PSScriptRoot 'third_party\defender-remover'

function Test-RemovalAssets {
    param([Parameter(Mandatory=$true)][string]$Root)
    $vendor = Join-Path $Root 'third_party\defender-remover'
    $manifest = Get-Content -LiteralPath (Join-Path $vendor 'manifest.json') -Raw | ConvertFrom-Json
    foreach ($asset in $manifest.Files) {
        $path = [IO.Path]::GetFullPath((Join-Path $Root $asset.Path))
        if (-not $path.StartsWith($Root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid asset path.' }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $asset.SHA256) { throw "Asset missing or modified: $($asset.Path)" }
    }
}

Test-RemovalAssets -Root $PSScriptRoot
. (Join-Path $PSScriptRoot 'Defender.Tools.ps1')
$platform = Get-DefenderPlatform
if ($platform.Build -lt 17763) { throw 'Security removal requires Windows 10 1809 / Server 2019 or newer.' }
if (-not [Environment]::Is64BitOperatingSystem) { throw 'Security removal requires 64-bit Windows.' }
if (-not $Apply) {
    Write-Ui 'PREVIEW: removes/disables Defender, Windows Security, UAC, SmartScreen and upstream registry protections.'
    Write-Ui 'LTSC 2019 (17763), LTSC 2021 (19044), Windows 10/11 and Server use detected paths/packages.'
    Write-Ui 'No changes. Use the interactive X menu to review and explicitly confirm.'
    return
}
if (-not $PSCmdlet.ShouldProcess($platform.Caption, 'Remove Defender/Security UI and disable UAC/SmartScreen')) { return }
if (-not $Worker) {
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) { throw 'Administrator rights required.' }
    $ReportPath = Join-Path $PSScriptRoot ('security-removal-' + [guid]::NewGuid().ToString('N') + '.json')
    $powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}" -Apply -Worker -ReportPath "{2}" -Language {3}' -f $powerShell,$PSCommandPath,$ReportPath,$env:DEBLOAT_LANGUAGE
    Start-Process -FilePath (Join-Path $vendor 'PowerRun.exe') -ArgumentList $arguments -WorkingDirectory $vendor -Wait | Out-Null
    # PowerRun may return before the worker. Wait for its completion report, with a bound.
    $deadline = (Get-Date).AddMinutes(15)
    while (-not (Test-Path -LiteralPath $ReportPath)) {
        if ((Get-Date) -ge $deadline) { throw 'No completion report after 15 minutes. Worker outcome is unknown; do not assume removal succeeded.' }
        Start-Sleep -Seconds 1
    }
    $report = Get-Content -LiteralPath $ReportPath -Raw | ConvertFrom-Json
    Write-Ui "Result: $($report.Status) | Report: $ReportPath" -ForegroundColor Cyan
    Write-Ui 'Restart Windows manually, then use V in the Defender menu to inspect remaining components.'
    return
}

if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -ne 'S-1-5-18') { throw 'Worker must be launched as SYSTEM by PowerRun.' }
$resolvedReport = [IO.Path]::GetFullPath($ReportPath)
if ([IO.Path]::GetDirectoryName($resolvedReport) -ne $PSScriptRoot -or [IO.Path]::GetFileName($resolvedReport) -notmatch '^security-removal-[a-f0-9]{32}\.json$') { throw 'Invalid report target.' }
$issues = New-Object 'System.Collections.Generic.List[string]'
function Invoke-RemovalStep([string]$Name, [scriptblock]$Action) {
    try { & $Action | Out-Null; Write-Ui "[DONE] $Name" }
    catch { $issues.Add("${Name}: $($_.Exception.Message)"); Write-Ui "[FAILED] $Name" -ForegroundColor Yellow }
}
try {
    foreach ($name in @('SecHealthUI','SecurityHealthSystray','smartscreen','MsMpEng','NisSrv')) {
        Invoke-RemovalStep "Stop $name" { Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop }
    }
    Invoke-RemovalStep 'Remove Windows Security app packages' {
        $apps = @(Get-AppxPackage -AllUsers -ErrorAction Stop | Where-Object { $_.Name -in @('Microsoft.Windows.SecHealthUI','Microsoft.SecHealthUI') })
        foreach ($app in $apps) {
            & "$env:SystemRoot\System32\dism.exe" /Online /Set-NonRemovableAppPolicy "/PackageFamily:$($app.PackageFamilyName)" /NonRemovable:0 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "DISM non-removable policy: $LASTEXITCODE" }
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
        }
        foreach ($app in @(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -in @('Microsoft.Windows.SecHealthUI','Microsoft.SecHealthUI') })) {
            Remove-AppxProvisionedPackage -Online -PackageName $app.PackageName -AllUsers -ErrorAction Stop | Out-Null
        }
    }
    foreach ($reg in @(Get-ChildItem -LiteralPath (Join-Path $vendor 'Remove_Defender'),(Join-Path $vendor 'Remove_SecurityComp') -Filter *.reg -File | Sort-Object FullName)) {
        Invoke-RemovalStep $reg.Name {
            & "$env:SystemRoot\System32\reg.exe" import $reg.FullName | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "reg import exit code $LASTEXITCODE" }
        }
    }
    Invoke-RemovalStep 'Disable UAC' {
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
        New-ItemProperty -LiteralPath $key -Name EnableLUA -PropertyType DWord -Value 0 -Force | Out-Null
    }
    Invoke-RemovalStep 'Remove Defender scheduled tasks' {
        Get-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender\' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction Stop
    }
    $targets = @(
        (Join-Path $env:ProgramData 'Microsoft\Windows Defender'),
        (Join-Path $env:ProgramFiles 'Windows Defender'),
        (Join-Path $env:ProgramFiles 'Windows Defender Advanced Threat Protection'),
        (Join-Path $env:SystemRoot 'System32\smartscreen.exe'),
        (Join-Path $env:SystemRoot 'System32\smartscreen.dll'),
        (Join-Path $env:SystemRoot 'System32\smartscreenps.dll')
    )
    if (${env:ProgramFiles(x86)}) { $targets += Join-Path ${env:ProgramFiles(x86)} 'Windows Defender' }
    $targets += @(Get-ChildItem -LiteralPath (Join-Path $env:SystemRoot 'SystemApps') -Directory | Where-Object { $_.Name -match '^(Microsoft\.Windows\.SecHealthUI|Microsoft\.SecHealthUI)_[a-zA-Z0-9]+$' } | Select-Object -ExpandProperty FullName)
    foreach ($target in $targets) {
        Invoke-RemovalStep "Remove $target" {
            $absolute = [IO.Path]::GetFullPath($target)
            $roots = @($env:ProgramData,$env:ProgramFiles,${env:ProgramFiles(x86)},$env:SystemRoot) | Where-Object { $_ }
            $inside = @($roots | Where-Object { $absolute.StartsWith($_.TrimEnd('\') + '\',[StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
            if (-not $inside -or $absolute -ne $target) { throw 'Removal path validation failed.' }
            if (Test-Path -LiteralPath $absolute) {
                $item = Get-Item -LiteralPath $absolute -Force
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing a reparse point.' }
                if ($item.PSIsContainer -and @(Get-ChildItem -LiteralPath $absolute -Force -Recurse -Attributes ReparsePoint -ErrorAction Stop).Count) { throw 'Refusing a tree with reparse points.' }
                Remove-Item -LiteralPath $absolute -Recurse -Force -ErrorAction Stop
            }
        }
    }
} catch { $issues.Add($_.Exception.Message) }
finally {
    try { $state = Get-ExperimentalSecurityState } catch { $state = $null; $issues.Add("Verification: $($_.Exception.Message)") }
    $status = 'PendingRestartVerification'
    if ($issues.Count) { $status = 'PartialOrFailed' }
    $report = [ordered]@{ Date=(Get-Date).ToString('o'); Platform=$platform; Status=$status; Errors=@($issues.ToArray()); State=$state; RestartRequired=$true }
    $temporary = $resolvedReport + '.tmp'
    $report | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $temporary -Encoding UTF8
    Move-Item -LiteralPath $temporary -Destination $resolvedReport -Force
}
