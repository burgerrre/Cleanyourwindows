#requires -Version 5.1
$ErrorActionPreference='Stop'
$exe=Join-Path $PSScriptRoot 'dist\Cleanyourwindows.exe'
$zip=Join-Path $PSScriptRoot 'dist\Cleanyourwindows-Portable.zip'
$assembly=[Reflection.Assembly]::LoadFile($exe)
$resource=$assembly.GetManifestResourceStream('payload.zip')
$sha=[Security.Cryptography.SHA256]::Create()
try { $actual=[BitConverter]::ToString($sha.ComputeHash($resource)).Replace('-','') }
finally { $resource.Dispose(); $sha.Dispose() }
if ($actual -ne (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash) { throw 'EXE embeds a different ZIP.' }
Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem
$archive=[IO.Compression.ZipFile]::OpenRead($zip)
try {
    foreach ($required in @('Start-Debloat.ps1','START.cmd','START-CONSOLE.cmd','Start-WebUi.ps1','Web.Core.ps1','Web.Worker.ps1','web/index.html','web/app.js','web/style.css','Localization.ps1','Languages.json','Install.Apps.ps1','Install.Catalog.json','Install.Strings.json','Experimental.SecurityRemoval.ps1','third_party/defender-remover/PowerRun.exe')) {
        if (@($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -eq $required }).Count -ne 1) { throw "Missing payload file: $required" }
    }
    $manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'third_party\defender-remover\manifest.json') -Raw | ConvertFrom-Json
    foreach ($asset in $manifest.Files) {
        $entry=@($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -eq $asset.Path })
        if ($entry.Count -ne 1) { throw "Missing pinned asset: $($asset.Path)" }
        $stream=$entry[0].Open(); $sha=[Security.Cryptography.SHA256]::Create()
        try { $hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') }
        finally { $stream.Dispose(); $sha.Dispose() }
        if ($hash -ne $asset.SHA256) { throw "Packaged asset hash mismatch: $($asset.Path)" }
    }
} finally { $archive.Dispose() }
# Invoke only the extraction path of the managed launcher. This does not start
# PowerShell, request elevation, or run any removal/activation command.
$arguments=[object[]]::new(1)
$arguments[0]=[string[]]@('--extract-only')
$code=$assembly.EntryPoint.Invoke($null,$arguments)
if ($code -ne 0) { throw 'EXE extraction failed.' }
Write-Host 'PASS: EXE resource, portable payload, pinned hashes and extraction-only execution. No app removal executed.' -ForegroundColor Green
