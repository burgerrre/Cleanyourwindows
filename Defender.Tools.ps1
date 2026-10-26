# Experimental feature removal for Windows Server.
function Get-DefenderPlatform {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $version = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
    $edition = [string]$version.EditionID
    $server = [int]$os.ProductType -ne 1
    $build = [int]$os.BuildNumber
    $ltsc = $edition -match '^(EnterpriseS|EnterpriseSN|IoTEnterpriseS|IoTEnterpriseSK)$' -or $os.Caption -match 'LTSC|LTSB'
    $family = 'Windows (older/unknown)'
    if ($server) { $family = 'Windows Server' }
    elseif ($build -ge 22000) { $family = 'Windows 11' }
    elseif ($build -ge 10240) { $family = 'Windows 10' }
    $supported = $server -and $build -ge 14393 -and [bool](Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue) -and [bool](Get-Command Uninstall-WindowsFeature -ErrorAction SilentlyContinue)
    $reason = 'На клиентской Windows нет штатной деинсталляции встроенного Defender Antivirus.'
    if ($server) { $reason = 'Нужен Windows Server 2016+ с модулем ServerManager и компонентом Windows-Defender.' }
    if ($supported) { $reason = 'Доступна штатная деинсталляция серверного компонента.' }
    [pscustomobject]@{
        Family=$family; Caption=[string]$os.Caption; Edition=$edition; Build=$build
        LTSC=[bool]$ltsc; Server=$server; Supported=[bool]$supported; Reason=$reason
    }
}

function Invoke-DefenderFeatureRemoval {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param()
    $platform = Get-DefenderPlatform
    if (-not $platform.Supported) { throw $platform.Reason }
    $names = @('Windows-Defender','Windows-Defender-Gui')
    $features = @(Get-WindowsFeature -Name 'Windows-Defender*' -ErrorAction Stop | Where-Object { $_.Name -in $names -and $_.Installed })
    if (-not $features.Count) {
        return [pscustomobject]@{ Platform=$platform; Status='NotInstalled'; RestartRequired=$false; Remaining=@() }
    }
    if (-not $PSCmdlet.ShouldProcess(($features.Name -join ', '), 'Uninstall Microsoft Defender Antivirus server features and remove payload')) { return }
    $result = Uninstall-WindowsFeature -Name @($features.Name) -Remove -Restart:$false -ErrorAction Stop
    if (-not $result.Success) { throw "ServerManager сообщил об ошибке: $($result.ExitCode)" }
    $remaining = @(Get-WindowsFeature -Name 'Windows-Defender*' -ErrorAction Stop | Where-Object { $_.Name -in $names -and $_.Installed } | Select-Object -ExpandProperty Name)
    $restart = [string]$result.RestartNeeded -eq 'Yes'
    $status = 'Removed'
    if ($restart) { $status = 'PendingRestart' }
    elseif ($remaining.Count) { $status = 'StillInstalled' }
    [pscustomobject]@{ Platform=$platform; Status=$status; RestartRequired=$restart; Remaining=$remaining }
}

function Get-ExperimentalSecurityState {
    $services = @('WinDefend','WdNisSvc','WdFilter','WdBoot','WdNisDrv','SecurityHealthService','wscsvc','Sense')
    $remaining = @($services | Where-Object { Test-Path -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$_" })
    $packages = @(Get-AppxPackage -AllUsers -ErrorAction Stop | Where-Object { $_.Name -in @('Microsoft.Windows.SecHealthUI','Microsoft.SecHealthUI') } | Select-Object -ExpandProperty PackageFullName)
    [pscustomobject]@{
        RemainingServiceKeys=$remaining; RemainingSecurityAppPackages=$packages
        EnableLUA=(Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -ErrorAction Stop).EnableLUA
        SmartScreen=(Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name SmartScreenEnabled -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SmartScreenEnabled -ErrorAction SilentlyContinue)
        DefenderDirectoryPresent=(Test-Path -LiteralPath (Join-Path $env:ProgramFiles 'Windows Defender'))
        SmartScreenFilePresent=(Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\smartscreen.exe'))
    }
}

function Show-DefenderMenu {
    try {
        Clear-Host
        Show-DebloatBanner
        $platform = Get-DefenderPlatform
        Write-Host '  DEFENDER / EXPERIMENTAL' -ForegroundColor Yellow
        Write-Host "  Система: $($platform.Caption)"
        Write-Host "  Семейство: $($platform.Family) | Сборка: $($platform.Build)"
        Write-Host "  Редакция: $($platform.Edition) | LTSC/LTSB: $($platform.LTSC)"
        Write-Host "`n  E = экспериментальное удаление Defender + Security UI, отключение UAC/SmartScreen" -ForegroundColor Yellow
        Write-Host '  V = проверить текущее состояние   S = штатное удаление на Server   Enter = назад'
        $choice = (Read-Host '  Команда').Trim().ToUpperInvariant()
        if ($choice -eq 'V') { Get-ExperimentalSecurityState | Format-List | Out-Host; return }
        if ($choice -eq 'E') {
            Write-Host '  Используются включённые исходники ionuttbara/windows-defender-remover.' -ForegroundColor Yellow
            Write-Host '  Также меняются VBS, mitigation-политики и связанные защитные компоненты из исходника.'
            Write-Host '  Операция необратима без резервной копии/переустановки. Сделай образ системы.'
            Write-Host '  Автоперезагрузки нет. LTSC 2019/2021 допускаются, но на них не выполнен runtime-тест.'
            if ((Read-Host '  Для запуска введи REMOVE SECURITY') -ceq 'REMOVE SECURITY') {
                & (Join-Path $PSScriptRoot 'Experimental.SecurityRemoval.ps1') -Apply
            }
            return
        }
        if ($choice -ne 'S') { return }
        Write-Host "`n  $($platform.Reason)" -ForegroundColor Cyan
        if (-not $platform.Supported) {
            Write-Host '  Удаление для этой системы недоступно. Изменений не будет.' -ForegroundColor Yellow
            return
        }
        Write-Host '  Будет удалён встроенный антивирус и файлы серверного компонента.' -ForegroundColor Yellow
        Write-Host '  Для восстановления может понадобиться источник установки Windows Server.'
        Write-Host '  Автоматической перезагрузки не будет. После удаления защита Defender недоступна.'
        if ((Read-Host "`n  Введи REMOVE DEFENDER для удаления; Enter = назад") -cne 'REMOVE DEFENDER') { return }
        $result = Invoke-DefenderFeatureRemoval
        if ($null -eq $result) { return }
        $reportPath = Join-Path $PSScriptRoot ('defender-report-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.json')
        $result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportPath -Encoding UTF8
        Write-Host "`n  Результат: $($result.Status) | Нужна перезагрузка: $($result.RestartRequired)" -ForegroundColor Cyan
        Write-Host "  Отчёт: $reportPath"
        if ($result.RestartRequired) { Write-Host '  Требуется перезагрузка. После неё повторно проверь компонент.' -ForegroundColor Yellow }
    } catch { Write-Host "  $($_.Exception.Message)" -ForegroundColor Red }
    finally { Read-Host "`n  Enter: вернуться в меню" | Out-Null }
}
