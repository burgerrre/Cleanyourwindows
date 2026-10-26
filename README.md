# Windows Debloat Deletor

Скрипт для **Windows PowerShell 5.1 от имени администратора** в Windows 10/11.
Удаление на компьютере автора при подготовке скрипта не запускалось.

1. Закройте Edge, Word, Excel, PowerPoint и другие удаляемые приложения.
2. Откройте Windows PowerShell от имени администратора.
3. Перейдите в папку со скриптом и откройте меню:

```powershell
cd C:\path\to\Cleanyourwindows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Remove-WindowsBloat.ps1
```

Или нажмите правой кнопкой на `Start-Debloat.ps1` → **Выполнить с помощью
PowerShell**: запуск запросит права администратора.

В меню WINDOWS DEBLOAT DELETOR отображаются 13 групп приложений и их наличие
на компьютере. Изначально ничего не выбрано. Введите номера через пробел
(`1 3 8`), чтобы поставить или снять отметки. `A` выбирает всё найденное,
`N` снимает выбор, `P` показывает выбранные приложения и пояснения,
`D` открывает подтверждение удаления, `Q` закрывает меню. Для запуска удаления
из меню нужно ввести `DELETE` после просмотра итогового списка.
После удаления скрипт через 4 секунды автоматически возвращается в меню,
повторно сканирует приложения и сбрасывает выбор. Можно выбрать следующую
группу или выйти командой `Q`. Для каждого удаления сохраняется отдельный отчёт.
Возврат в меню работает при запуске через `Start-Debloat.ps1` и при обычном
запуске основного скрипта; команды с `-Apply`, `-Preview` или `-WhatIf`
выполняются один раз.
Найденными считаются также пакеты, предустановленные для будущих пользователей.

Для просмотра без интерактивного меню:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Remove-WindowsBloat.ps1 -Preview
```

Следующие команды **пропускают меню** и сразу запускают удаление.
Удалить Edge, Microsoft 365 и Copilot:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Remove-WindowsBloat.ps1 -Apply
```

Удалить также дополнительные приложения:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Remove-WindowsBloat.ps1 -Apply -IncludeExtras
```

`-IncludeExtras` добавляет Clipchamp, новости, погоду, пасьянсы, People, Power Automate,
To Do, Feedback Hub, карты, приложения Xbox, Groove/Movies, Phone Link, Skype и Teams.
Удаление Xbox Game Bar отключит его оверлей и запись. Это конкретный список,
а не автоматическое удаление всего, что скрипт посчитает ненужным.

`-KeepEdge`, `-KeepOffice`, `-KeepCopilot` исключают соответствующий компонент.
`-Apply -WhatIf` показывает действия без удаления и без записи отчёта.
`-Preview -IncludeExtras` показывает полный список без меню.
В меню доступны все группы; `-Keep*` исключает соответствующие группы из него.

Синтаксис PowerShell 5.1 и сценарии выбора/отмены проверены автоматически.
Повторить тесты меню без удаления: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Test-DebloatMenu.ps1`.

Appx-пакеты удаляются для всех пользователей, а provisioned-пакеты — из набора
для новых учётных записей. Обычные программы удаляются зарегистрированными
деинсталляторами Microsoft; могут появляться окна с вопросами. Microsoft 365
удаляется вместе с входящими в комплект Word/Excel/PowerPoint. Бессрочные Office,
отдельные Visio/Project и установленные у других пользователей Win32-программы
за пределами доступных веток реестра не охватываются.

Отчёт `debloat-report-*.json` содержит ошибки, остаточный список установленных
пакетов и разницу свободного места на системном диске. В режиме предварительного
просмотра наличие приложений в остаточном списке ожидаемо. Установщик может
завершать удаление после перезагрузки: после неё запустите просмотр повторно.

**«Полностью» здесь означает деинсталляцию приложения и удаление доступного
предустановленного пакета, а не стирание каждого следа.** Профили Edge,
документы Office и прочие пользовательские данные сохраняются. Скрипт не
чистит Temp, корзину, Downloads, кэши других программ или WinSxS и не меняет
Defender, Windows Update, службы и права доступа к системным папкам.

В части сборок Windows Edge защищён от удаления. Скрипт пробует зарегистрированный
деинсталлятор с `--force-uninstall`, проверяет остаточный список и сообщает
о неудаче. Общий компонент WebView2 сохраняется. Встроенный legacy Copilot
и системные AI-компоненты, не оформленные как перечисленные приложения,
этим скриптом не удаляются. Обновления Windows могут вернуть приложения.

Документация Microsoft:

- [Ограничения удаления Edge](https://support.microsoft.com/en-us/edge/why-can-t-i-uninstall-microsoft-edge)
- [Удаление Copilot](https://learn.microsoft.com/en-us/windows/client-management/manage-windows-copilot)
- [Удаление Microsoft 365](https://support.microsoft.com/en-us/office/lifecycle/officeinstall/uninstall-microsoft-365-or-office-from-a-pc)

Если обычное удаление Microsoft 365 не завершилось, используйте официальный
инструмент [Get Help / OfficeScrubScenario](https://learn.microsoft.com/en-us/troubleshoot/microsoft-365/admin/miscellaneous/get-help-office-uninstall).
