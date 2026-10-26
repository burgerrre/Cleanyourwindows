#requires -Version 5.1
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Debloat.Menu.ps1')
$previousLanguage=$env:DEBLOAT_LANGUAGE
try {
    foreach ($choice in @(@('1','EN'),@('2','RU'),@('en','EN'),@('ru','RU'))) {
        & {
            function Clear-Host { }
            function Write-Host { param($Object,$ForegroundColor) }
            function Read-Host { param($Prompt) $choice[0] }
            Select-UiLanguage
        }
        if ($env:DEBLOAT_LANGUAGE -ne $choice[1]) { throw 'Language selection failed.' }
    }
    foreach ($language in @('RU','EN')) {
        Set-UiLanguage $language
        $catalog=@(Get-DebloatCatalog)
        if ($catalog.Count -ne 13) { throw 'Localized catalog changed package selection.' }
        if ($language -eq 'EN' -and (($catalog.Title + $catalog.Note) -join ' ') -match '[А-Яа-яЁё]') { throw 'English catalog contains untranslated Russian.' }
        & {
            $script:captured=New-Object 'System.Collections.Generic.List[string]'
            function Write-Host { param($Object,$ForegroundColor,$NoNewline) $script:captured.Add([string]$Object) }
            function Clear-Host { }
            function Read-Host { param($Prompt) $script:captured.Add($Prompt); 'Q' }
            Show-DebloatMenu -Catalog $catalog -PresentIds @('edge','office') | Out-Null
            if ($language -eq 'EN' -and ($script:captured -join ' ') -match '[А-Яа-яЁё]') { throw 'English menu contains untranslated Russian.' }
            if ($language -eq 'RU' -and ($script:captured -join ' ') -notmatch 'Удалить|удалить') { throw 'Russian menu was not rendered.' }
        }
    }
    Set-UiLanguage EN
    if ((Get-UiText 'Удалить выбранное? [y/N]') -ne 'Uninstall the selected apps? [y/N]') { throw 'Confirmation translation failed.' }
    Set-UiLanguage RU
    if ((Get-UiText 'Selected groups: edge') -ne 'Выбранные группы: edge') { throw 'Russian operation output failed.' }
} finally { $env:DEBLOAT_LANGUAGE=$previousLanguage }
Write-Host 'PASS: RU/EN selection, both menu languages, catalog and confirmation translations. No removal executed.' -ForegroundColor Green
