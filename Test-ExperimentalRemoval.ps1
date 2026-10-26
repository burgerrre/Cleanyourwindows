#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
foreach ($file in @(Get-ChildItem -LiteralPath $root -Filter *.ps1 -File)) {
    $tokens=$null; $errors=$null
    [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors) | Out-Null
    if ($errors.Count) { throw "Parse failure: $($file.Name): $errors" }
}
$manifest=Get-Content -LiteralPath (Join-Path $root 'third_party\defender-remover\manifest.json') -Raw | ConvertFrom-Json
foreach ($file in $manifest.Files) {
    if ((Get-FileHash -LiteralPath (Join-Path $root $file.Path) -Algorithm SHA256).Hash -ne $file.SHA256) { throw "Integrity failed: $($file.Path)" }
}
# Load definitions without executing the runner or any privileged tool.
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'Experimental.SecurityRemoval.ps1'),[ref]$tokens,[ref]$errors)
$functions=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Test-RemovalAssets'},$true))
$vendor=Join-Path $root 'third_party\defender-remover'
. ([scriptblock]::Create($functions[0].Extent.Text))
Test-RemovalAssets -Root $root
& {
    function Get-FileHash { param($LiteralPath,$Algorithm) [pscustomobject]@{Hash='TAMPERED'} }
    $rejected=$false
    try { Test-RemovalAssets -Root $root } catch { $rejected=$true }
    if (-not $rejected) { throw 'Modified asset was accepted.' }
}
. (Join-Path $root 'Debloat.Menu.ps1')
& {
    $queue=New-Object 'System.Collections.Generic.Queue[string]'
    foreach ($line in @('E','n','')) { $queue.Enqueue($line) }
    function Read-Host { param($Prompt) if (-not $queue.Count) { throw 'Unexpected prompt' }; $queue.Dequeue() }
    function Write-Host { param($Object,$ForegroundColor) }
    function Clear-Host { }
    function Get-DefenderPlatform { [pscustomobject]@{ Caption='LTSC 2021'; Family='Windows 10'; Build=19044; Edition='EnterpriseS'; LTSC=$true; Supported=$false; Reason='Client' } }
    # Any attempt to launch the worker/tool fails the cancellation test.
    function Start-Process { throw 'Unexpected privileged process in cancellation test' }
    Show-DefenderMenu
    if ($queue.Count) { throw 'Experimental menu did not consume confirmation and return.' }
}
Write-Host 'PASS: syntax, pinned asset integrity, LTSC experimental entry and cancellation. No removal executed.' -ForegroundColor Green
