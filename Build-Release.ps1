#requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root=$PSScriptRoot
$output=Join-Path $root 'dist'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$manifestPath=Join-Path $root 'third_party\defender-remover\manifest.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
foreach ($entry in $manifest.Files) {
    $entry.SHA256=(Get-FileHash -LiteralPath (Join-Path $root $entry.Path) -Algorithm SHA256).Hash
}
$manifest | ConvertTo-Json -Depth 4 | ForEach-Object {
    [IO.File]::WriteAllText($manifestPath, $_.Replace("`r`n","`n"),[Text.UTF8Encoding]::new($true))
}
$names=@('Start-Debloat.ps1','Remove-WindowsBloat.ps1','Debloat.Menu.ps1','Defender.Tools.ps1',
    'Experimental.SecurityRemoval.ps1','Localization.ps1','Languages.json','Install.Apps.ps1','Install.Catalog.json','Install.Strings.json','START.cmd','README.md','LICENSE','third_party')
$zip=Join-Path $output 'Cleanyourwindows-Portable.zip'
Compress-Archive -LiteralPath @($names | ForEach-Object { Join-Path $root $_ }) -DestinationPath $zip -Force
$compiler=Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { $compiler=Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path -LiteralPath $compiler)) { throw '.NET Framework C# compiler not found.' }
$exe=Join-Path $output 'Cleanyourwindows.exe'
& $compiler /nologo /target:exe /platform:anycpu /optimize+ "/out:$exe" "/win32manifest:$root\build\Launcher.manifest" "/resource:$zip,payload.zip" /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll (Join-Path $root 'build\Launcher.cs')
if ($LASTEXITCODE -ne 0) { throw "C# compilation failed: $LASTEXITCODE" }
$hashes=@(Get-FileHash -LiteralPath $exe,$zip -Algorithm SHA256 | ForEach-Object { $_.Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetFileName($_.Path) })
[IO.File]::WriteAllLines((Join-Path $output 'SHA256SUMS.txt'),$hashes,[Text.UTF8Encoding]::new($false))
Write-Host "Built: $exe"
