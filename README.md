# Cleanyourwindows — Windows Debloat Deletor

**[Download Cleanyourwindows.exe](https://github.com/burgerrre/Cleanyourwindows/releases/latest/download/Cleanyourwindows.exe)**

## Русский

### Как запустить

1. Скачай **Cleanyourwindows.exe** в разделе [Releases](https://github.com/burgerrre/Cleanyourwindows/releases).
2. Запусти EXE и разреши запуск от администратора.
3. Выбери **2 — Русский** или **1 — English**.
4. Выбери приложения, затем `D`. Подтверждение: `y` — да, `n` или Enter — отмена.

**Обычному пользователю нужен только EXE.** Остальные PS1-файлы — исходники и
вспомогательные модули. Для Portable ZIP распакуй весь архив и запусти **START.cmd**.
Запускать каждый PS1 по очереди не нужно.

EXE содержит комплект файлов, распаковывает его в
`%LOCALAPPDATA%\Cleanyourwindows\Sessions\<сеанс>` и открывает меню.
Отчёты остаются в папке сеанса. Интернет для распаковки не нужен.
EXE и включённый сторонний PowerRun не имеют цифровой подписи.

### Управление

| Команда | Действие |
| --- | --- |
| `1 3 8` | Поставить/снять отметки у групп приложений |
| `A` / `N` | Выбрать всё найденное / снять выбор |
| `P` / `D` | Просмотр выбранного / удаление |
| `W` | Активация Windows действующей лицензией |
| `X` | Defender, Windows Security, UAC и SmartScreen |
| `Q` | Выход |

После удаления приложений меню возвращается через 4 секунды, список сканируется
заново, выбор сбрасывается. Личные документы, профили Edge, корзина, Downloads
и кэши других программ не очищаются.

В список входят Edge, Microsoft 365 (включая Word/Excel/PowerPoint из подписки),
Copilot, Xbox/Game Bar, Clipchamp, Teams, Phone Link и другие указанные приложения.
Windows может запретить удаление Edge. Общий компонент WebView2 сохраняется.
`W` использует штатные средства Windows; ключ вводится в параметрах Windows
и не сохраняется скриптом.

### Раздел X

- **E** — удаление Defender/Windows Security и отключение UAC/SmartScreen по включённым правилам стороннего проекта.
- **S** — штатная деинсталляция Defender на Windows Server 2016+.
- **V** — просмотр остаточных компонентов и настроек.

E допускает 64-разрядную Windows 10 1809+, включая LTSC 2019 (17763), LTSC 2021 (19044),
Windows 11 и Server 2019+. Помимо Defender/UAC/SmartScreen применяются включённые
правила изменения VBS, mitigation-политик и других защит. Раздел X не входит
в «выбрать всё». Перед изменениями нужен образ системы: надёжного автоматического
отката нет. Перезагрузка выполняется вручную.

Результат записывается в JSON. `PartialOrFailed` означает ошибки;
`PendingRestartVerification` требует перезагрузки и проверки через X → V.
Заблокированные файлы могут остаться; обновления Windows могут вернуть компоненты.
Завершение процесса не доказывает полного удаления.

Проверены синтаксис, меню, RU/EN, отмена, целостность и упаковка.
Реальное удаление на LTSC 2019/2021 и работа EXE на этих системах не проверялись.

## English

### Start here

1. Download **Cleanyourwindows.exe** from [Releases](https://github.com/burgerrre/Cleanyourwindows/releases).
2. Run it and accept the administrator prompt.
3. Choose **1 — English** or **2 — Русский**.
4. Select applications, press `D`, then answer `y` to proceed or `n`/Enter to cancel.

**The EXE is the only file end users need.** PS1 files are source/support modules.
For the Portable ZIP, extract the entire archive and run **START.cmd**.
The EXE extracts its bundled files to
`%LOCALAPPDATA%\Cleanyourwindows\Sessions\<session>`; reports remain there.
Extraction does not require internet access. The EXE and bundled PowerRun are unsigned.

Type numbers such as `1 3 8` to toggle groups. `A` selects installed groups,
`N` clears selection, `P` previews, `D` removes, `W` opens Windows activation,
`X` opens security component management, and `Q` exits. The app menu rescans
and reopens four seconds after removal. Personal documents and browser profiles
are preserved. Edge removal may be blocked by Windows; WebView2 is preserved.
Activation requires a valid license; keys are entered in Windows Settings.

### Security component management

X → E attempts Defender/Security UI removal and disables UAC/SmartScreen using
bundled upstream registry rules. It admits 64-bit Windows 10 1809+, LTSC 2019/2021,
Windows 11 and Server 2019+. It also changes VBS, mitigation policies and related
security settings. X → S is the standard Server feature uninstall;
X → V displays remaining components. These changes are separate from Select All.

Create a full system image first: there is no reliable automatic undo. Restart
manually and check X → V. JSON reports preserve failures and remaining state.
Locked files may remain and Windows servicing can restore components. Process
completion is not proof of complete removal. Actual removal and EXE execution
have not been validated on LTSC 2019/2021.

Windows tools and dialogs use the operating system's language. JSON status
identifiers remain stable across UI languages.

## Source, licenses and build

Third-party revision: `6126092a5376753153295a20806ebd2f5f3e1c0e` of
[ionuttbara/windows-defender-remover](https://github.com/ionuttbara/windows-defender-remover).
See [NOTICE](third_party/defender-remover/NOTICE.md) and its separate CC BY-NC 4.0
license. The top-level license does not replace third-party licenses. PowerRun
is Sordum freeware. SHA-256 pins included bytes; it does not authenticate the publisher.

Build on Windows with .NET Framework 4.x and Windows PowerShell 5.1:

```powershell
.\Build-Release.ps1
```

Or use `build-release.cmd`. Outputs: `dist/Cleanyourwindows.exe`,
`dist/Cleanyourwindows-Portable.zip`, `dist/SHA256SUMS.txt`.
The launcher is compiled from `build/Launcher.cs`; it embeds the complete ZIP,
requests administrator privileges and invokes the included PowerShell entry point.

Checks (no actual removal): `Test-DebloatMenu.ps1`, `Test-DefenderTools.ps1`,
`Test-ExperimentalRemoval.ps1`, `Test-Localization.ps1`.