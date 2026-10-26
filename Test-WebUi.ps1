#requires -Version 5.1
# Starts a real loopback server in -Demo mode. No system operations are run.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Web.Core.ps1')
$parent=Join-Path $PSScriptRoot '.test-artifacts'
$runtime=Join-Path $parent ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$process=$null;$session=$null
function Invoke-WebCheck([string]$Path,[string]$Method='GET',$Body=$null,[string]$Token='',[string]$Origin='',[string]$HostName='') {
    $request=[Net.HttpWebRequest]::Create($session.origin+$Path)
    $request.Method=$Method;$request.Timeout=8000;$request.KeepAlive=$false;$request.AllowAutoRedirect=$false
    if ($Token) {$request.Headers['X-Cleanyourwindows-Token']=$Token}
    if ($Origin) {$request.Headers['Origin']=$Origin}
    if ($HostName) {$request.Host=$HostName}
    if ($Method -eq 'POST') {
        $request.ContentType='application/json'
        $bytes=[Text.Encoding]::UTF8.GetBytes(($Body|ConvertTo-Json -Depth 5 -Compress))
        $request.ContentLength=$bytes.Length
        $output=$request.GetRequestStream();$output.Write($bytes,0,$bytes.Length);$output.Dispose()
    }
    try {$response=$request.GetResponse()} catch [Net.WebException] {if (-not $_.Exception.Response) {throw};$response=$_.Exception.Response}
    try {
        $reader=[IO.StreamReader]::new($response.GetResponseStream(),[Text.Encoding]::UTF8)
        try {$text=$reader.ReadToEnd()} finally {$reader.Dispose()}
        [pscustomobject]@{status=[int]$response.StatusCode;text=$text;csp=$response.Headers['Content-Security-Policy']}
    } finally {$response.Dispose()}
}
function Assert-WebStatus($Result,[int]$Expected) {if ($Result.status -ne $Expected) {throw "Expected HTTP $Expected, got $($Result.status): $($Result.text)"}}
try {
    foreach ($invalid in @(
        @{action='cmd';ids=@('whoami')},
        @{action='install';ids=@('firefox','powershell.exe')},
        @{action='uninstall';ids=@()},
        @{action='install';ids=@('firefox');language='FR'}
    )) {
        $rejected=$false
        try {Test-WebAction ([pscustomobject]$invalid)|Out-Null} catch {$rejected=$true}
        if (-not $rejected) {throw 'Invalid web action was accepted.'}
    }
    $plan=@(Get-WebPlan ([pscustomobject]@{action='install';ids=@('vencord');language='EN'}))
    if (($plan.id -join ',') -ne 'discord,vencord' -or -not $plan[0].dependency) {throw 'Web installation plan lost dependencies.'}
    $arguments='-NoProfile -ExecutionPolicy Bypass -File "{0}" -Demo -NoBrowser -RuntimeDirectory "{1}"' -f (Join-Path $PSScriptRoot 'Start-WebUi.ps1'),$runtime
    $process=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtime 'server.log') -RedirectStandardError (Join-Path $runtime 'error.log')
    $path=Join-Path $runtime 'session.json'
    for ($i=0;$i -lt 80 -and -not (Test-Path $path);$i++) {Start-Sleep -Milliseconds 100}
    if (-not (Test-Path $path)) {throw 'Demo server failed to start.'}
    $session=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json
    $r=Invoke-WebCheck '/';Assert-WebStatus $r 200
    if ($r.csp -notmatch "frame-ancestors 'none'" -or $r.csp -notmatch "script-src 'self'") {throw 'Browser security headers are missing.'}
    Assert-WebStatus (Invoke-WebCheck '/api/state') 403
    Assert-WebStatus (Invoke-WebCheck '/api/state' -Token 'wrong-token') 403
    Assert-WebStatus (Invoke-WebCheck '/api/state' -Token $session.token -HostName 'evil.example') 403
    $r=Invoke-WebCheck '/api/state' -Token $session.token;Assert-WebStatus $r 200
    $state=$r.text|ConvertFrom-Json
    if (-not $state.catalog.demo -or $state.catalog.installation.Count -ne 16 -or $state.catalog.removal.Count -ne 13) {throw 'Demo catalog is incomplete.'}
    $body=@{action='install';ids=@('vencord');language='EN'}
    Assert-WebStatus (Invoke-WebCheck '/api/plan' 'POST' $body $session.token) 403
    Assert-WebStatus (Invoke-WebCheck '/api/plan' 'POST' $body $session.token 'https://evil.example') 403
    $r=Invoke-WebCheck '/api/plan' 'POST' $body $session.token $session.origin;Assert-WebStatus $r 200
    if ((($r.text|ConvertFrom-Json).items.id -join ',') -ne 'discord,vencord') {throw 'HTTP plan was incorrect.'}
    Assert-WebStatus (Invoke-WebCheck '/api/run' 'POST' $body $session.token $session.origin) 400
    $body.confirmed='true'
    Assert-WebStatus (Invoke-WebCheck '/api/run' 'POST' $body $session.token $session.origin) 400
    $body.confirmed=$true
    Assert-WebStatus (Invoke-WebCheck '/api/run' 'POST' $body $session.token $session.origin) 202
    Assert-WebStatus (Invoke-WebCheck '/api/run' 'POST' $body $session.token $session.origin) 409
    Assert-WebStatus (Invoke-WebCheck '/api/refresh' -Token $session.token) 404
    for ($i=0;$i -lt 25;$i++) {
        Start-Sleep -Milliseconds 200
        $state=(Invoke-WebCheck '/api/state' -Token $session.token).text|ConvertFrom-Json
        if (-not $state.busy) {break}
    }
    if ($state.busy -or $state.jobs.Count -ne 1 -or $state.jobs[0].status -ne 'completed' -or ($state.jobs[0].logs -join ' ') -notmatch 'No system changes') {throw 'Demo job did not complete without system changes.'}
    Assert-WebStatus (Invoke-WebCheck '/api/refresh' 'POST' @{} $session.token $session.origin) 200
    Assert-WebStatus (Invoke-WebCheck '/api/shutdown' 'POST' @{} 'wrong-token' $session.origin) 403
    Assert-WebStatus (Invoke-WebCheck '/api/shutdown' 'POST' @{} $session.token $session.origin) 200
    $process.WaitForExit(5000)|Out-Null
    if (-not $process.HasExited) {throw 'Server did not stop after shutdown.'}
    Write-Host 'PASS: live demo HTTP server, token/host/origin checks, explicit confirmation, dependency plans, single-job lock, simulated completion and shutdown.' -ForegroundColor Green
} finally {
    if ($process -and -not $process.HasExited) {Stop-Process -Id $process.Id -Force}
    $absolute=[IO.Path]::GetFullPath($runtime)
    if (-not $absolute.StartsWith([IO.Path]::GetFullPath($parent).TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)) {throw 'Unsafe test cleanup path.'}
    Remove-Item -LiteralPath $absolute -Recurse -Force
}
