#requires -Version 5.1
param([switch]$Console,[switch]$Demo)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Localization.ps1')
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin -and -not $Demo) {
    try {
        $arguments=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath))
        if ($Console) {$arguments+='-Console'}
        $parameters=@{FilePath=(Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe');Verb='RunAs';ArgumentList=$arguments}
        if (-not $Console) {$parameters.WindowStyle='Hidden'}
        Start-Process @parameters | Out-Null
    } catch { Write-Ui 'Запуск отменён или не удалось получить права администратора.' -ForegroundColor Yellow }
    return
}
try {
    if ($Console) {& (Join-Path $PSScriptRoot 'Remove-WindowsBloat.ps1')}
    else {& (Join-Path $PSScriptRoot 'Start-WebUi.ps1') -Demo:$Demo}
} catch {
    if ($Console) {Write-Ui $_.Exception.Message -ForegroundColor Red}
    else {Add-Type -AssemblyName System.Windows.Forms;[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Cleanyourwindows') | Out-Null}
    exit 1
}
if ($Console) {Read-Ui 'Enter: завершить' | Out-Null}
