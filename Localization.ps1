function Set-UiLanguage {
    param([ValidateSet('RU','EN')][string]$Language)
    $env:DEBLOAT_LANGUAGE = $Language
}

function Select-UiLanguage {
    while ($true) {
        Clear-Host
        Write-Host '  WINDOWS DEBLOAT DELETOR' -ForegroundColor Cyan
        Write-Host '  1. English (EN)'
        Write-Host '  2. Русский (RU)'
        $answer = (Read-Host '  Language / Язык [1/2]').Trim().ToUpperInvariant()
        if ($answer -in @('1','EN')) { Set-UiLanguage EN; return }
        if ($answer -in @('2','RU')) { Set-UiLanguage RU; return }
    }
}

if (-not $env:DEBLOAT_LANGUAGE) { Set-UiLanguage RU }
$script:UiTranslations = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Languages.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$script:UiEnglishLookup=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
$script:UiRussianLookup=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($pair in $script:UiTranslations) {
    if ($pair.RU) { $script:UiEnglishLookup[[string]$pair.RU]=[string]$pair.EN }
    if ($pair.EnglishFirst -and $pair.EN) { $script:UiRussianLookup[[string]$pair.EN]=[string]$pair.RU }
}
$script:UiEnglishPattern=(@($script:UiEnglishLookup.Keys | Sort-Object Length -Descending | ForEach-Object {[regex]::Escape($_)}) -join '|')
$script:UiRussianPattern=(@($script:UiRussianLookup.Keys | Sort-Object Length -Descending | ForEach-Object {[regex]::Escape($_)}) -join '|')

function Get-UiText {
    param([AllowEmptyString()][string]$Text)
    # Translate original text in one pass. Never translate generated fragments
    # a second time, which can corrupt longer sentences and product names.
    if ($env:DEBLOAT_LANGUAGE -eq 'EN') {
        $lookup=$script:UiEnglishLookup; $pattern=$script:UiEnglishPattern
    } else {
        $lookup=$script:UiRussianLookup; $pattern=$script:UiRussianPattern
    }
    if (-not $Text -or -not $pattern) { return $Text }
    return [regex]::Replace($Text,$pattern,[Text.RegularExpressions.MatchEvaluator]{param($match) $lookup[$match.Value]})
}

function Write-Ui {
    param([AllowEmptyString()][object]$Object, [ConsoleColor]$ForegroundColor, [switch]$NoNewline)
    $options = @{ Object=(Get-UiText ([string]$Object)); NoNewline=[bool]$NoNewline }
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) { $options.ForegroundColor=$ForegroundColor }
    Write-Host @options
}

function Read-Ui {
    param([string]$Prompt)
    Read-Host (Get-UiText $Prompt)
}
