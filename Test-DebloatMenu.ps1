#requires -Version 5.1
# Tests exercise input/selection only. No package enumeration or removal.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Debloat.Menu.ps1')
$catalog = @(Get-DebloatCatalog)
if ($catalog.Count -ne 13) { throw 'Unexpected catalog size.' }
if (@($catalog.Id | Select-Object -Unique).Count -ne $catalog.Count) { throw 'Duplicate catalog IDs.' }
$parsed = @(ConvertTo-DebloatNumbers '1, 3; 3 8' 13)
if (($parsed -join ',') -ne '1,3,8') { throw 'Number parsing failed.' }
foreach ($bad in @('0','14','1 nope','-1','')) {
    $rejected = $false
    try { ConvertTo-DebloatNumbers $bad 13 | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw "Invalid input accepted: $bad" }
}
function Invoke-MenuScenario([string[]]$Inputs, [string[]]$Present) {
    $queue = New-Object 'System.Collections.Generic.Queue[string]'
    foreach ($inputLine in $Inputs) { $queue.Enqueue($inputLine) }
    function Read-Host {
        param([string]$Prompt)
        if ($queue.Count -eq 0) { throw 'Menu requested unexpected input.' }
        return $queue.Dequeue()
    }
    function Write-Host { param($Object, $ForegroundColor) }
    function Clear-Host { }
    $answer = Show-DebloatMenu -Catalog $catalog -PresentIds $Present
    if ($queue.Count -ne 0) { throw 'Menu returned before consuming scenario.' }
    return $answer
}
$answer = Invoke-MenuScenario @('1 3','P','','D','y') @('edge','copilot')
if (($answer.Ids -join ',') -ne 'edge,copilot') { throw 'Preview changed the selection.' }
$answer = Invoke-MenuScenario @('A','N','D','3','D','','D','y') @('edge','copilot')
if (($answer.Ids -join ',') -ne 'copilot') { throw 'Clear/cancel behavior failed.' }
$answer = Invoke-MenuScenario @('1 3','1','D',' Y ') @('edge','copilot')
if (($answer.Ids -join ',') -ne 'copilot') { throw 'Toggle behavior failed.' }
$answer = Invoke-MenuScenario @('2','D','A','D','y') @('edge')
if (($answer.Ids -join ',') -ne 'edge') { throw 'Absent application could be selected.' }
$answer = Invoke-MenuScenario @('A','Q') @('edge')
if ($null -ne $answer) { throw 'Quit returned a removal selection.' }
$answer = Invoke-MenuScenario @('A','D','n','Q') @('edge')
if ($null -ne $answer) { throw 'Negative confirmation was accepted.' }
Write-Host 'PASS: catalog, input validation and 6 interactive scenarios. No uninstall operations executed.' -ForegroundColor Green

# Mock activation entry points: tests never change the license.
& {
    $queue = New-Object 'System.Collections.Generic.Queue[string]'
    foreach ($line in @('1','','2','','3','','Q')) { $queue.Enqueue($line) }
    $calls = New-Object 'System.Collections.Generic.List[string]'
    function Read-Host { param([string]$Prompt) if (-not $queue.Count) { throw 'Unexpected activation input.' }; $queue.Dequeue() }
    function Clear-Host { }
    function Write-Host { param($Object, $ForegroundColor) }
    function Invoke-WindowsLicenseTool { param($Option) $calls.Add($Option) }
    function Open-WindowsActivationSettings { $calls.Add('settings') }
    Show-WindowsActivationMenu
    if (($calls -join ',') -ne '/dli,/xpr,settings,/ato,/dli') { throw 'Activation menu dispatch failed.' }
    if ($queue.Count) { throw 'Activation menu did not return on Q.' }
}
Write-Host 'PASS: activation menu dispatch and return (mocked; no license changes).' -ForegroundColor Green
