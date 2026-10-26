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
$script:UiTranslations = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Languages.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$script:UiEnglishTranslations = @($script:UiTranslations | Sort-Object { $_.RU.Length } -Descending)
$script:UiRussianTranslations = @($script:UiTranslations | Where-Object { $_.EnglishFirst } | Sort-Object { $_.EN.Length } -Descending)

function Get-UiText {
    param([AllowEmptyString()][string]$Text)
    $result = $Text
    if ($env:DEBLOAT_LANGUAGE -eq 'EN') {
        foreach ($pair in $script:UiEnglishTranslations) {
            $result = $result.Replace([string]$pair.RU,[string]$pair.EN)
        }
    } else {
        # Only English-first messages are translated back; translated Russian
        # strings are never processed twice.
        foreach ($pair in $script:UiRussianTranslations) {
            $result = $result.Replace([string]$pair.EN,[string]$pair.RU)
        }
    }
    return $result
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
