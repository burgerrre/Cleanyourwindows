# Cleanyourwindows — Windows Debloat Deletor

**Web UI preview — ветка `test/web-ui`. Стабильная версия `main` не изменена.**

**[Download Web UI preview EXE](https://github.com/burgerrre/Cleanyourwindows/releases/download/v1.2.0-webui.1/Cleanyourwindows.exe)**

## Русский

### Как запустить

1. Скачай **Cleanyourwindows.exe** в разделе [Releases](https://github.com/burgerrre/Cleanyourwindows/releases).
2. Запусти EXE и разреши запуск от администратора.
3. Откроется локальный интерфейс в браузере. Выбери **Русский** или **English**.
4. Открой «Удаление» или «Установка», отметь карточки и нажми «Проверить выбор».
5. Просмотри список и подтверди действие кнопкой. Ход выполнения появится в журнале.

**Обычному пользователю нужен только EXE.** Остальные PS1-файлы — исходники и
вспомогательные модули. Для Portable ZIP распакуй весь архив и запусти **START.cmd**.
Запускать каждый PS1 по очереди не нужно.

EXE содержит комплект файлов, распаковывает его в
`%LOCALAPPDATA%\Cleanyourwindows\Sessions\<сеанс>` и открывает меню.
Отчёты остаются в папке сеанса. Интернет для распаковки не нужен.
EXE и включённый сторонний PowerRun не имеют цифровой подписи.

### Web UI

В боковом меню: обзор компьютера, удаление, установка, системные компоненты и журнал.
Есть поиск, фильтры, выбор карточками, просмотр зависимостей и переключение RU/EN.
Интерфейс работает через 127.0.0.1 в установленном современном браузере (Firefox,
Chrome, Brave или Edge); WebView2 не требуется. UI и шрифты не загружаются из интернета.

Для действий нужны права администратора. Служба слушает только loopback; API требует
случайный ключ сеанса, правильный Host/Origin и явное подтверждение. Одновременно
выполняется только одна операция. Закрытие программы доступно в боковом меню; после
пяти минут без активной вкладки и незавершённых задач сервер останавливается.
Отчёты GUI сохраняются в папке сеанса `.webui-runtime`.

Посмотреть дизайн без изменений системы: `Cleanyourwindows.exe --demo` или
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-WebUi.ps1 -Demo`.
Демонстрационный режим использует пример каталога и имитирует операции.

### Консольный режим

Старый интерфейс доступен через **START-CONSOLE.cmd** или `Cleanyourwindows.exe --console`.

### Управление в консоли

| Команда | Действие |
| --- | --- |
| `1 3 8` | Поставить/снять отметки у групп приложений |
| `A` / `N` | Выбрать всё найденное / снять выбор |
| `P` / `D` | Просмотр выбранного / удаление |
| `I` | Выбор и установка программ |
| `X` | Defender, Windows Security, UAC и SmartScreen |
| `Q` | Выход |

После удаления приложений меню возвращается через 4 секунды, список сканируется
заново, выбор сбрасывается. Личные документы, профили Edge, корзина, Downloads
и кэши других программ не очищаются.

В список входят Edge, Microsoft 365 (включая Word/Excel/PowerPoint из подписки),
Copilot, Xbox/Game Bar, Clipchamp, Teams, Phone Link и другие указанные приложения.
Windows может запретить удаление Edge. Общий компонент WebView2 сохраняется.

### Установка программ — I

Выбирай программы номерами. `A` выбирает все, `N` снимает выбор, `P` показывает
очередь с зависимостями, `I` запускает установку после ответа `y`, `Q` возвращает
в меню удаления. Устанавливается только выбранное и его зависимости. Ошибка
одной установки не прерывает остальные. Результаты сохраняются в
`install-report-*.json` в папке сеанса.

Доступны Firefox, VLC, OBS Studio, TG WS Proxy, zapret, Discord, Vencord, Happ
для Windows, 7-Zip, Steam, Prism Launcher, Codex / ChatGPT desktop,
Google Antigravity, Claude Code, Telegram Desktop и отдельный Codex CLI.

Обычные приложения ставятся через WinGet с точными идентификаторами пакетов.
Уже установленные программы пропускаются. Если WinGet отсутствует, он автоматически устанавливается перед выбранными программами
официальным модулем Microsoft.WinGet.Client из PSGallery. Дополнительно нажимать `B`
не нужно: эта команда остаётся для ручного восстановления.
Потребуется интернет. Подтверждение установки означает принятие условий выбранных
приложений и источников пакетов. Некоторые приложения требуют новую сборку Windows.
Codex / ChatGPT desktop использует Microsoft Store и недоступен на системах без
работающего Store; отдельный Codex CLI устанавливается через источник winget.

TG WS Proxy, zapret и Happ скачиваются из последних стабильных релизов указанных
репозиториев, а Vencord — из официального Vencord/Installer. Выбирается Windows-файл
для архитектуры системы, проверяются размер и SHA-256 из GitHub Release API.
Если контрольная сумма отсутствует или не совпала, запуск останавливается.

Портативные TG WS Proxy и zapret размещаются в `%ProgramData%\Cleanyourwindows\Apps`
с ярлыками в Пуск → Cleanyourwindows. Папка zapret при необходимости переносится
в `%SystemDrive%\CleanyourwindowsApps`, чтобы путь не содержал кириллицу.
У zapret нужно открыть ярлык настройки и выбрать рабочую стратегию; служба
автоматически не создаётся. Vencord добавляет Discord Stable как зависимость
и запускает официальный CLI-установщик с `-install -branch stable`; перед этим
закрой Discord. Happ открывает штатный мастер установки Windows — его шаги
нужно завершить самостоятельно. Это явно отмечено в списке и отчёте.

Источники: [TG WS Proxy](https://github.com/Flowseal/tg-ws-proxy),
[zapret](https://github.com/Flowseal/zapret-discord-youtube),
[Happ](https://github.com/Happ-proxy/happ-desktop),
[Vencord](https://vencord.dev/download/),
[WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/),
[Codex / приложение OpenAI](https://learn.chatgpt.com/docs/windows/windows-app),
[Claude Code](https://code.claude.com/docs/en/setup),
[Google Antigravity](https://antigravity.google/download).

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

Проверены синтаксис, меню, RU/EN, отмена, очередь установок, проверки загрузок, целостность и упаковка. Настоящая установка приложений не запускалась.
Реальное удаление на LTSC 2019/2021 и работа EXE на этих системах не проверялись.

## English

### Start here

1. Download **Cleanyourwindows.exe** from [Releases](https://github.com/burgerrre/Cleanyourwindows/releases).
2. Run it and accept the administrator prompt.
3. The local browser interface opens. Choose **English** or **Русский**.
4. Open Uninstall apps or Install apps, select cards, and review your selection.
5. Confirm in the dialog and follow progress in Activity.

**The EXE is the only file end users need.** PS1 files are source/support modules.
For the Portable ZIP, extract the entire archive and run **START.cmd**.
The EXE extracts its bundled files to
`%LOCALAPPDATA%\Cleanyourwindows\Sessions\<session>`; reports remain there.
Extraction does not require internet access. The EXE and bundled PowerRun are unsigned.

### Web UI preview

This branch adds Overview, Uninstall apps, Install apps, Security, and Activity.
The UI includes search, filters, card selection, dependency review, confirmation
dialogs, live output, and RU/EN. It uses the default modern browser (Firefox,
Chrome, Brave, or Edge), not WebView2. UI assets and fonts are bundled offline.

The server binds only to IPv4 loopback. API calls require a random session token;
Host/Origin checks, JSON-only POSTs, explicit confirmation, one-operation locking,
and a restrictive content security policy are enforced. Operations run in separate
PowerShell workers. The server exits after five idle minutes when no job is running.
GUI reports are stored under the session's `.webui-runtime` directory.

Use `Cleanyourwindows.exe --demo` to explore a simulated catalog without system
changes. `Start-WebUi.ps1 -Demo` also runs without administrator rights. The old
console menu is available with **START-CONSOLE.cmd** or the EXE's `--console` option.

In console mode, type numbers such as `1 3 8` to toggle groups. `A` selects installed groups,
`N` clears selection, `P` previews, `D` removes,
`I` opens the app installer, `X` manages security components, and `Q` exits. The app menu rescans
and reopens four seconds after removal. Personal documents and browser profiles
are preserved. Edge removal may be blocked by Windows; WebView2 is preserved.

### Install applications — I

Select apps by number. `A` selects all, `N` clears the selection, `P` reviews the
queue, `I` starts installation after a `y` confirmation, and `Q` returns to the
uninstall menu. Dependencies are listed before you confirm. A failed app does
not stop the rest of the queue. Results are saved to `install-report-*.json`.

The catalog includes Firefox, VLC, OBS Studio, TG WS Proxy, zapret, Discord,
Vencord, Happ for Windows, 7-Zip, Steam, Prism Launcher, Codex / ChatGPT desktop,
Google Antigravity, Claude Code, Telegram Desktop, and a separate Codex CLI option.

Standard apps use exact WinGet package IDs and skip apps already installed.
If WinGet is missing, it is installed automatically before the selected apps using
Microsoft's Microsoft.WinGet.Client module from PSGallery. No extra `B` action is
needed; it remains available for manual repair. Downloads require internet access.
Continuing accepts the selected installers' and package sources' terms.
The OpenAI desktop app requires a working Microsoft Store; Codex CLI is available
separately without Store. Individual apps may require a newer Windows build.

GitHub downloads come from the projects' stable releases. Windows assets are
selected by architecture and checked against the size and SHA-256 digest published
by GitHub. A missing or mismatched checksum prevents execution. TG WS Proxy and
zapret get persistent files under `%ProgramData%\Cleanyourwindows\Apps` and Start
menu shortcuts. zapret uses `%SystemDrive%\CleanyourwindowsApps` if an ASCII-only
path is needed. Open its shortcut to select a strategy; no service is installed
automatically. Vencord adds Discord Stable to the queue and runs the official
CLI installer with `-install -branch stable`; close Discord first. Happ opens its
Windows setup wizard, which you must complete. The app list and report distinguish
portable files, verified WinGet installs, and installers requiring follow-up.

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
`Test-ExperimentalRemoval.ps1`, `Test-Localization.ps1`, `Test-AppInstaller.ps1`, `Test-WingetBootstrap.ps1`, `Test-Release.ps1`.
## Web UI development checks

`Test-WebUi.ps1` starts a real demo server and checks authentication, Origin/Host,
confirmation, dependency plans, job locking and shutdown. It never runs system actions.

Browser checks use Playwright (dev dependency only; end users do not need Node.js).
Start `Start-WebUi.ps1 -Demo -NoBrowser`, then install dev dependencies with `npm install`
and run `npm run test:browser -- .webui-runtime/session.json`. Install a Playwright
Chromium browser with `npx playwright install chromium` or set `WEBUI_BROWSER` to an
existing Chromium-based browser executable. Screenshots go next to the session JSON.

The preview was checked in Windows PowerShell 5.1 and a real headless Chromium-based
browser. Real uninstall/install/security operations through the new UI have not been
executed on the development computer. The existing function and installer tests remain
available. The main branch and stable release are not changed by this preview.