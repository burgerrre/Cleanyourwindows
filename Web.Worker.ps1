#requires -Version 5.1
param([Parameter(Mandatory=$true)][string]$RequestPath,[Parameter(Mandatory=$true)][string]$ResultPath)
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
. (Join-Path $PSScriptRoot 'Web.Core.ps1')
$directory=[IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($ResultPath))
$status='failed';$detail='';$data=$null
try {
    $request=Test-WebAction (Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    Set-UiLanguage $request.language
    switch ($request.action) {
        'install' {
            $data=@(Invoke-AppInstallation -Ids $request.ids -ReportDirectory $directory)
            $status='completed'
            if (@($data | Where-Object {$_.Status -in @('Failed','BlockedDependency','NeedsSetup')}).Count) {$status='attention'}
        }
        'uninstall' {
            & (Join-Path $PSScriptRoot 'Remove-WindowsBloat.ps1') -Apply -SelectedGroups $request.ids -Language $request.language -ReportDirectory $directory
            $report=Get-ChildItem -LiteralPath $directory -Filter debloat-report-*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if (-not $report) {throw 'Uninstall report was not produced.'}
            $data=Get-Content -LiteralPath $report.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $status='completed'
            if ($data.RebootRequired) {$status='restart'}
            if (@($data.Results | Where-Object Status -eq 'Failed').Count -or @($data.RemainingAppx).Count -or @($data.RemainingProvisioned).Count -or @($data.RemainingDesktop).Count) {$status='attention'}
        }
        'repairWinget' {Install-AppWinget;$status='completed'}
        'security' {
            & (Join-Path $PSScriptRoot 'Experimental.SecurityRemoval.ps1') -Apply -Language $request.language
            # The security runner writes a separate report and always needs follow-up.
            $status='attention';$detail='Check the security-removal report and restart Windows manually.'
        }
        'serverSecurity' {$data=Invoke-DefenderFeatureRemoval;$status='completed';if ($data.RestartRequired) {$status='restart'};if ($data.Status -eq 'StillInstalled') {$status='attention'}}
    }
} catch { $detail=$_.Exception.Message; Write-Output $detail }
finally {
    $result=[ordered]@{status=$status;detail=$detail;finished=(Get-Date).ToString('o');data=$data}
    $temporary=$ResultPath+'.tmp'
    $result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $temporary -Encoding UTF8
    Move-Item -LiteralPath $temporary -Destination $ResultPath -Force
}
