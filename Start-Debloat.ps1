#requires -Version 5.1
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Localization.ps1')
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    try {
        Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -Verb RunAs -ArgumentList @(
            '-NoProfile', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
        ) | Out-Null
    } catch { Write-Ui 'Запуск отменён или не удалось получить права администратора.' -ForegroundColor Yellow }
    return
}
try { & (Join-Path $PSScriptRoot 'Remove-WindowsBloat.ps1') }
catch { Write-Ui $_.Exception.Message -ForegroundColor Red }
Read-Ui 'Enter: завершить' | Out-Null
