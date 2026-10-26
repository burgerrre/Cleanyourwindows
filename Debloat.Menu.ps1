# Console UI and explicit package catalogue. No uninstall operations in this file.
function Get-DebloatCatalog {
    @(
        @{ Id='edge'; Title='Microsoft Edge'; Note='Браузер; Windows может запретить удаление'; Packages=@('Microsoft.MicrosoftEdge.Stable') },
        @{ Id='office'; Title='Microsoft 365 / Office Hub'; Note='Включая Word, Excel, PowerPoint из подписки 365'; Packages=@('Microsoft.MicrosoftOfficeHub','Microsoft.Office.Desktop','Microsoft.Microsoft365') },
        @{ Id='copilot'; Title='Microsoft Copilot'; Note='Приложение Copilot и его Appx-провайдер'; Packages=@('Microsoft.Copilot','Microsoft.Windows.Ai.Copilot.Provider') },
        @{ Id='clipchamp'; Title='Clipchamp'; Note='Видеоредактор'; Packages=@('Clipchamp.Clipchamp') },
        @{ Id='news'; Title='Новости и погода'; Note='Bing News / Weather'; Packages=@('Microsoft.BingNews','Microsoft.BingWeather') },
        @{ Id='xbox'; Title='Xbox и Game Bar'; Note='Xbox-приложения, оверлей и запись экрана'; Packages=@('Microsoft.XboxApp','Microsoft.GamingApp','Microsoft.XboxGamingOverlay','Microsoft.XboxGameOverlay','Microsoft.XboxSpeechToTextOverlay') },
        @{ Id='teams'; Title='Microsoft Teams / Skype'; Note='Приложения связи'; Packages=@('MicrosoftTeams','MSTeams','Microsoft.SkypeApp') },
        @{ Id='phone'; Title='Связь с телефоном'; Note='Phone Link'; Packages=@('Microsoft.YourPhone') },
        @{ Id='solitaire'; Title='Microsoft Solitaire'; Note='Коллекция пасьянсов'; Packages=@('Microsoft.MicrosoftSolitaireCollection') },
        @{ Id='media'; Title='Музыка и Кино'; Note='Groove Music / Movies & TV'; Packages=@('Microsoft.ZuneMusic','Microsoft.ZuneVideo') },
        @{ Id='productivity'; Title='To Do / People / Power Automate'; Note='Задачи, контакты и автоматизация'; Packages=@('Microsoft.Todos','Microsoft.People','Microsoft.PowerAutomateDesktop') },
        @{ Id='help'; Title='Советы / справка / отзывы'; Note='Get Started, Get Help, Feedback Hub'; Packages=@('Microsoft.Getstarted','Microsoft.GetHelp','Microsoft.WindowsFeedbackHub') },
        @{ Id='maps'; Title='Карты Windows'; Note='Приложение Maps'; Packages=@('Microsoft.WindowsMaps') }
    ) | ForEach-Object { [pscustomobject]$_ }
}

function Show-DebloatBanner {
    Write-Host @'
  __        _____ _   _ ____   _____        ______
  \ \      / /_ _| \ | |  _ \ / _ \ \      / / ___|
   \ \ /\ / / | ||  \| | | | | | | \ \ /\ / /\___ \
    \ V  V /  | || |\  | |_| | |_| |\ V  V /  ___) |
     \_/\_/  |___|_| \_|____/ \___/  \_/\_/  |____/

           D E B L O A T   D E L E T O R
  ===========================================================
'@ -ForegroundColor Cyan
    Write-Host '  Выбери приложения. Проверь список. Удали лишнее.' -ForegroundColor White
    Write-Host '  Личные файлы / Store / Defender / WebView2 сохраняются.' -ForegroundColor DarkGray
    Write-Host ''
}

function ConvertTo-DebloatNumbers([string]$Text, [int]$Count) {
    $parts = @($Text.Trim() -split '[,;\s]+' | Where-Object { $_ })
    if ($parts.Count -eq 0) { throw 'Введи номера через пробел, например: 1 3 8.' }
    $numbers = @()
    foreach ($part in $parts) {
        $number = 0
        if (-not [int]::TryParse($part, [ref]$number) -or $number -lt 1 -or $number -gt $Count) {
            throw "Номер '$part' вне списка 1..$Count."
        }
        $numbers += $number
    }
    return @($numbers | Select-Object -Unique)
}

function Show-DebloatMenu([object[]]$Catalog, [string[]]$PresentIds) {
    $selected = @{}
    $message = ''
    while ($true) {
        Clear-Host
        Show-DebloatBanner
        Write-Host '   #   ВЫБОР  ПРИЛОЖЕНИЕ                         НАЛИЧИЕ' -ForegroundColor DarkCyan
        for ($i = 0; $i -lt $Catalog.Count; $i++) {
            $item = $Catalog[$i]
            $present = $item.Id -in $PresentIds
            $mark = ' '
            if ($selected.ContainsKey($item.Id)) { $mark = 'X' }
            $state = 'не найдено'
            $color = 'DarkGray'
            if ($present) { $state = 'найдено'; $color = 'White' }
            if ($mark -eq 'X') { $color = 'Green' }
            Write-Host ('  {0,2}    [{1}]   {2,-34} {3}' -f ($i + 1), $mark, $item.Title, $state) -ForegroundColor $color
        }
        Write-Host ''
        Write-Host ('  Выбрано групп: {0}   |   Диск {1}: свободно {2:N1} ГБ' -f $selected.Count, $env:SystemDrive, ([IO.DriveInfo]::new($env:SystemDrive + '\').AvailableFreeSpace / 1GB)) -ForegroundColor Cyan
        Write-Host '  Номера: переключить выбор (например 1 3 8)' -ForegroundColor White
        Write-Host '  A = выбрать найденное   N = снять всё   P = план' -ForegroundColor White
        Write-Host '  D = удалить выбранное  Q = выход' -ForegroundColor White
        if ($message) { Write-Host "`n  $message" -ForegroundColor Yellow }
        $command = (Read-Host "`n  Команда").Trim()
        $message = ''
        switch ($command.ToUpperInvariant()) {
            'Q' { return $null }
            'A' { foreach ($item in $Catalog) { if ($item.Id -in $PresentIds) { $selected[$item.Id] = $true } }; continue }
            'N' { $selected.Clear(); continue }
            { $_ -in @('D','P') } {
                if ($selected.Count -eq 0) { $message = 'Сначала выбери хотя бы одно найденное приложение.'; continue }
                $chosen = @($Catalog | Where-Object { $selected.ContainsKey($_.Id) })
                Write-Host "`n  ВЫБРАННЫЙ СПИСОК:" -ForegroundColor Cyan
                foreach ($item in $chosen) { Write-Host "  - $($item.Title): $($item.Note)" }
                if ($command -ieq 'P') { Read-Host "`n  Enter: вернуться в меню" | Out-Null; continue }
                Write-Host "`n  Удаление затронет все учётные записи и пакеты для новых пользователей." -ForegroundColor Yellow
                Write-Host '  Закрой удаляемые программы. Может потребоваться перезагрузка.' -ForegroundColor Yellow
                if ((Read-Host '  Для запуска введи DELETE; Enter = назад') -ceq 'DELETE') {
                    return [pscustomobject]@{ Ids = @($chosen.Id) }
                }
                $message = 'Удаление отменено. Выбор сохранён.'
                continue
            }
            default {
                try {
                    $numbers = @(ConvertTo-DebloatNumbers $command $Catalog.Count)
                    foreach ($number in $numbers) {
                        $item = $Catalog[$number - 1]
                        if ($item.Id -notin $PresentIds) { $message = 'Не найденные приложения пропущены.'; continue }
                        if ($selected.ContainsKey($item.Id)) { $selected.Remove($item.Id) }
                        else { $selected[$item.Id] = $true }
                    }
                } catch { $message = $_.Exception.Message }
            }
        }
    }
}
