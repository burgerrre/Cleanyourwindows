#requires -Version 5.1
param([switch]$Demo,[switch]$NoBrowser,[int]$Port=0,[string]$RuntimeDirectory=(Join-Path $PSScriptRoot '.webui-runtime'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Web.Core.ps1')
if (-not $Demo) {
    $admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {throw 'Run as administrator, or use -Demo for a non-destructive preview.'}
}
$listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
$listener.Start()
$portNumber=([Net.IPEndPoint]$listener.LocalEndpoint).Port
$origin='http://127.0.0.1:'+ $portNumber
$random=[byte[]]::new(32);$rng=[Security.Cryptography.RandomNumberGenerator]::Create();$rng.GetBytes($random);$rng.Dispose()
$token=[BitConverter]::ToString($random).Replace('-','').ToLowerInvariant()
New-Item -ItemType Directory -Path $RuntimeDirectory -Force | Out-Null
$sessionPath=Join-Path $RuntimeDirectory 'session.json'
@{origin=$origin;token=$token;demo=[bool]$Demo;pid=$PID} | ConvertTo-Json | Set-Content -LiteralPath $sessionPath -Encoding UTF8
$jobs=New-Object 'System.Collections.Generic.List[object]'
$catalog=$null;$catalogTime=[datetime]::MinValue
$lastActivity=Get-Date;$running=$true
Write-Host ('Cleanyourwindows Web UI: '+$origin)
if (-not $NoBrowser) {try {Start-Process -FilePath ($origin+'/#token='+$token) | Out-Null} catch {Write-Warning 'Could not open the default browser. Use the session URL from session.json.'}}
function Send-Json($Stream,[int]$Status,$Object) { Send-WebResponse $Stream $Status 'application/json; charset=utf-8' ([Text.Encoding]::UTF8.GetBytes(($Object | ConvertTo-Json -Depth 12 -Compress))) }
function Update-WebJobs {
    foreach ($job in $jobs) {
        if ($job.status -ne 'running') {continue}
        if ($Demo) {
            if (((Get-Date)-$job.startedDate).TotalSeconds -gt 3) {$job.status='completed';$job.logs=@('Preview only. No system changes were made.');$catalog=$null}
        } elseif (Test-Path -LiteralPath $job.resultPath) {
            $result=Get-Content -LiteralPath $job.resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $job.status=$result.status;$job.detail=$result.detail
            $script:catalog=$null
        } elseif ($job.process.HasExited) {$job.status='failed';$job.detail='Worker exited without producing a report.'}
        if (-not $Demo -and (Test-Path -LiteralPath $job.logPath)) {
            $job.logs=@(Get-Content -LiteralPath $job.logPath -Tail 120 -Encoding UTF8 -ErrorAction SilentlyContinue)
            if (Test-Path -LiteralPath $job.errorPath) {$job.logs+=@(Get-Content -LiteralPath $job.errorPath -Tail 25 -Encoding UTF8 -ErrorAction SilentlyContinue)}
        }
    }
}
try {
    while ($running) {
        Update-WebJobs
        if (-not $listener.Pending()) {
            if (-not @($jobs | Where-Object status -eq 'running').Count -and ((Get-Date)-$lastActivity).TotalMinutes -gt 5) {break}
            Start-Sleep -Milliseconds 40;continue
        }
        $client=$listener.AcceptTcpClient();$stream=$client.GetStream();$stream.ReadTimeout=4000;$stream.WriteTimeout=4000
        try {
            $request=Read-WebRequest $stream
            if ($request.headers['host'] -ne ('127.0.0.1:'+$portNumber)) {Send-Json $stream 403 @{error='Invalid host.'};continue}
            $static=@{'/'='index.html';'/index.html'='index.html';'/app.js'='app.js';'/style.css'='style.css'}
            if ($request.method -eq 'GET' -and $static.ContainsKey($request.path)) {
                $type='text/html; charset=utf-8'
                if ($request.path -eq '/app.js') {$type='application/javascript; charset=utf-8'}
                if ($request.path -eq '/style.css') {$type='text/css; charset=utf-8'}
                Send-WebResponse $stream 200 $type ([IO.File]::ReadAllBytes((Join-Path (Join-Path $PSScriptRoot 'web') $static[$request.path])))
                continue
            }
            if ($request.headers['x-cleanyourwindows-token'] -cne $token) {Send-Json $stream 403 @{error='Invalid session token.'};continue}
            if ($request.headers.ContainsKey('origin') -and $request.headers['origin'] -ne $origin) {Send-Json $stream 403 @{error='Invalid origin.'};continue}
            if ($request.method -eq 'POST' -and ($request.headers['origin'] -ne $origin -or $request.headers['content-type'] -notmatch '^application/json(?:;|$)')) {Send-Json $stream 403 @{error='Expected same-origin JSON.'};continue}
            $lastActivity=Get-Date
            if ($request.method -eq 'GET' -and $request.path -eq '/api/state') {
                if (-not $catalog) {$catalog=Get-WebCatalog -Demo:$Demo;$catalogTime=Get-Date}
                $publicJobs=@($jobs | ForEach-Object {[pscustomobject]@{id=$_.id;action=$_.action;ids=$_.ids;status=$_.status;detail=$_.detail;started=$_.started;logs=@($_.logs)}})
                Send-Json $stream 200 @{catalog=$catalog;jobs=$publicJobs;busy=(@($jobs|Where-Object status -eq 'running').Count -gt 0)}
            } elseif ($request.method -eq 'POST' -and $request.path -eq '/api/plan') {
                $body=$request.body|ConvertFrom-Json
                $validated=Test-WebAction $body
                Send-Json $stream 200 @{items=@(Get-WebPlan $validated);action=$validated.action}
            } elseif ($request.method -eq 'POST' -and $request.path -eq '/api/run') {
                if (@($jobs | Where-Object status -eq 'running').Count) {Send-Json $stream 409 @{error='Another operation is already running.'};continue}
                $body=$request.body|ConvertFrom-Json
                if (-not $body.PSObject.Properties['confirmed'] -or $body.confirmed -isnot [bool] -or -not $body.confirmed) {Send-Json $stream 400 @{error='Explicit confirmation is required.'};continue}
                $validated=Test-WebAction $body
                $id=[guid]::NewGuid().ToString('N')
                $job=[pscustomobject]@{id=$id;action=$validated.action;ids=$validated.ids;status='running';detail='';started=(Get-Date).ToString('o');startedDate=(Get-Date);logs=@();process=$null;resultPath='';logPath='';errorPath=''}
                if (-not $Demo) {
                    $folder=Join-Path $RuntimeDirectory $id;New-Item -ItemType Directory -Path $folder | Out-Null
                    $inputPath=Join-Path $folder 'request.json';$job.resultPath=Join-Path $folder 'result.json';$job.logPath=Join-Path $folder 'output.log';$job.errorPath=Join-Path $folder 'error.log'
                    $validated|ConvertTo-Json -Depth 4|Set-Content -LiteralPath $inputPath -Encoding UTF8
                    $arguments='-NoProfile -ExecutionPolicy Bypass -File "{0}" -RequestPath "{1}" -ResultPath "{2}"' -f (Join-Path $PSScriptRoot 'Web.Worker.ps1'),$inputPath,$job.resultPath
                    $job.process=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $job.logPath -RedirectStandardError $job.errorPath
                } else {$job.logs=@('Preview: '+$validated.action+' / '+($validated.ids -join ', '))}
                $jobs.Add($job)
                Send-Json $stream 202 @{id=$id;status='running';demo=[bool]$Demo}
            } elseif ($request.method -eq 'POST' -and $request.path -eq '/api/refresh') {
                $catalog=$null;Send-Json $stream 200 @{ok=$true}
            } elseif ($request.method -eq 'POST' -and $request.path -eq '/api/shutdown') {
                if (@($jobs|Where-Object status -eq 'running').Count) {Send-Json $stream 409 @{error='Wait for the current operation to finish.'};continue}
                Send-Json $stream 200 @{ok=$true};$running=$false
            } else {Send-Json $stream 404 @{error='Not found.'}}
        } catch {
            try {Send-Json $stream 400 @{error=$_.Exception.Message}} catch {}
        } finally {$stream.Dispose();$client.Close()}
    }
} finally {$listener.Stop()}
