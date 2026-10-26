'use strict';

const words = {
  RU: {
    workspace:'РАБОЧАЯ ОБЛАСТЬ',workspaceName:'Мой компьютер',overview:'Обзор',uninstall:'Удаление',install:'Установка',security:'Безопасность',activity:'Журнал',oneStep:'Начни с малого',oneStepNote:'Выбирай только то, что тебе действительно не нужно.',quit:'Закрыть программу',connecting:'Подключение',connected:'Подключено',offline:'Нет соединения',loading:'Готовим рабочее пространство…',welcome:'ТВОЁ РАБОЧЕЕ ПРОСТРАНСТВО',overviewTitle:'Всё под твоим контролем',overviewNote:'Меньше лишнего. Больше места для нужного.',thisPC:'Этот компьютер',heroLabel:'ПОРЯДОК НАЧИНАЕТСЯ ЗДЕСЬ',heroTitle:'Windows.<br>Только нужное.',heroNote:'Удали лишние приложения, установи любимые и настрой систему под себя.',cleanButton:'Выбрать лишнее',installButton:'Установить программы',freeSpace:'Свободное место',of:'из',systemDrive:'Системный диск',detectedGroups:'Найдено приложений',detectedNote:'групп доступны для удаления',sessionActivity:'Операций за сеанс',noChanges:'Пока без изменений',runningNote:'Сейчас выполняется операция',quickCleanup:'Можно освободить место',viewAll:'Смотреть всё',popularApps:'Часто устанавливают',safeNote:'Документы, загрузки и профили браузеров сохраняются. Ты подтверждаешь каждую операцию.',detected:'Найдено в системе',notDetected:'Не найдено',add:'Выбрать',selected:'Выбрано',uninstallTitle:'Убери то, чем не пользуешься',uninstallNote:'Предустановленные приложения и компоненты. Личные файлы остаются на месте.',installTitle:'Собери свой набор программ',installNote:'Любимые приложения в одной очереди. WinGet установится автоматически, если понадобится.',search:'Найти приложение…',selectAll:'Выбрать всё',clearSelection:'Снять выбор',shown:'показано',all:'Все',browser:'Браузеры',media:'Медиа',communication:'Общение',network:'Сеть',gaming:'Игры',coding:'Разработка',tools:'Утилиты',selectedFilter:'Выбранные',ready:'Готово к установке',review:'Проверить выбор',selectedCount:'Выбрано: {n}',dockRemove:'Удаление для всех пользователей. Сначала покажем список.',dockInstall:'Зависимости будут добавлены в очередь перед подтверждением.',emptySearch:'Ничего не найдено',emptySearchNote:'Попробуй другое название или сбрось фильтр.',confirmRemove:'Удалить выбранные приложения?',confirmInstall:'Установить выбранные программы?',confirmNoteRemove:'Изменения затронут все учётные записи и пакеты для новых пользователей. Закрой выбранные приложения перед запуском.',confirmNoteInstall:'Для загрузки нужен интернет. WinGet и зависимости установятся при необходимости. Продолжение означает принятие условий выбранных установщиков и источников.',dependency:'Добавлено как зависимость',cancel:'Нет, вернуться',yesRemove:'Да, удалить',yesInstall:'Да, установить',starting:'Запускаем…',operationStarted:'Операция запущена. Ход выполнения — в журнале.',busy:'Дождись завершения текущей операции.',demo:'Демонстрационный режим: действия имитируются, система не изменяется.',demoShort:'Демо',securityTitle:'Системные компоненты',securityNote:'Дополнительные действия для тех, кто понимает их последствия.',securityCardTitle:'Defender, UAC и SmartScreen',securityCardNote:'Удаление Windows Security и Defender, отключение UAC и SmartScreen по включённым правилам стороннего проекта. Также меняются связанные защитные политики.',securityWarning:'После этих изменений защита компьютера снижается. Надёжного автоматического отката нет — сначала сохрани образ системы. Перезагрузку нужно выполнить вручную.',reviewChanges:'Посмотреть изменения',serverTitle:'Штатное удаление на Windows Server',serverNote:'Деинсталляция серверного компонента Windows-Defender средствами ServerManager. На обычной Windows 10/11 этот способ недоступен.',serverAction:'Удалить серверный компонент',securityConfirm:'Изменить системные защиты?',securityConfirmNote:'Будут применены правила удаления Defender / Windows Security и отключения UAC / SmartScreen. Они затрагивают VBS, mitigation-политики и другие защитные компоненты. Нужна резервная копия системы. Полное удаление не гарантируется.',yesSecurity:'Да, применить изменения',wingetTitle:'Менеджер установки WinGet',wingetNote:'WinGet устанавливается автоматически вместе с выбранными программами. Здесь можно отдельно восстановить его, если установка не работает.',repairWinget:'Восстановить WinGet',repairConfirm:'Восстановить WinGet?',repairNote:'Будут установлены или обновлены Microsoft.WinGet.Client и WinGet из источников Microsoft. Нужен интернет.',yesRepair:'Да, восстановить',activityTitle:'Всё, что происходит',activityNote:'Результаты и вывод программ за этот сеанс.',noActivity:'Здесь появятся операции',noActivityNote:'Выбери приложения для удаления или установки. Все действия будут показаны здесь.',running:'Выполняется',completed:'Завершено',attention:'Проверь результат',failed:'Ошибка',restart:'Нужна перезагрузка',uninstallJob:'Удаление приложений',installJob:'Установка программ',repairWingetJob:'Восстановление WinGet',securityJob:'Изменение защитных компонентов',serverSecurityJob:'Удаление Defender на Server',jobCount:'Приложений: {n}',waitingLog:'Ожидаем вывод программы…',refresh:'Обновить список',refreshed:'Список обновлён',connectionError:'Не удалось подключиться к программе',connectionErrorNote:'Открой интерфейс через Cleanyourwindows.exe. Сервер мог завершить работу; повторный запуск создаст новый сеанс.',requestFailed:'Не удалось выполнить запрос',shutdown:'Программа закрыта. Эту вкладку можно закрыть.',lastStatus:'Последняя операция',chooseLanguage:'Выбрать язык'
  },
  EN: {
    workspace:'WORKSPACE',workspaceName:'My computer',overview:'Overview',uninstall:'Uninstall apps',install:'Install apps',security:'Security',activity:'Activity',oneStep:'Start small',oneStepNote:'Choose only the apps you no longer need.',quit:'Close application',connecting:'Connecting',connected:'Connected',offline:'Disconnected',loading:'Getting your workspace ready…',welcome:'YOUR WORKSPACE',overviewTitle:'A little more control',overviewNote:'Less clutter. More room for what matters.',thisPC:'This computer',heroLabel:'A FRESH START FOR YOUR PC',heroTitle:'Windows.<br>Just what you need.',heroNote:'Remove unwanted apps, install your favorites, and make your PC feel like yours.',cleanButton:'Choose apps to remove',installButton:'Install applications',freeSpace:'Free disk space',of:'of',systemDrive:'System drive',detectedGroups:'Apps detected',detectedNote:'app groups available to uninstall',sessionActivity:'Operations this session',noChanges:'No changes yet',runningNote:'An operation is in progress',quickCleanup:'Make some room',viewAll:'View all',popularApps:'Popular essentials',safeNote:'Documents, downloads, and browser profiles are preserved. You confirm every operation.',detected:'Detected on this PC',notDetected:'Not detected',add:'Select',selected:'Selected',uninstallTitle:'Keep what you actually use',uninstallNote:'Remove preinstalled apps and components. Your personal files stay where they are.',installTitle:'Build your app collection',installNote:'Your favorite apps, one installation queue. WinGet is installed automatically when needed.',search:'Search applications…',selectAll:'Select all',clearSelection:'Clear selection',shown:'shown',all:'All apps',browser:'Browsers',media:'Media',communication:'Communication',network:'Network',gaming:'Gaming',coding:'Development',tools:'Utilities',selectedFilter:'Selected',ready:'Ready to install',review:'Review selection',selectedCount:'{n} selected',dockRemove:'Uninstall affects all accounts. Review the list before continuing.',dockInstall:'Required dependencies will be added before you confirm.',emptySearch:'No matching apps',emptySearchNote:'Try another name or clear the filter.',confirmRemove:'Uninstall the selected apps?',confirmInstall:'Install the selected apps?',confirmNoteRemove:'This affects all user accounts and apps provisioned for new accounts. Close the selected applications before continuing.',confirmNoteInstall:'Downloads require internet access. WinGet and dependencies are installed when needed. Continuing accepts the selected installers’ and package sources’ terms.',dependency:'Added as a dependency',cancel:'No, go back',yesRemove:'Yes, uninstall',yesInstall:'Yes, install',starting:'Starting…',operationStarted:'Operation started. Follow its progress in Activity.',busy:'Wait for the current operation to finish.',demo:'Preview mode: actions are simulated. No system changes are made.',demoShort:'Preview',securityTitle:'System components',securityNote:'Additional controls for users who understand the consequences.',securityCardTitle:'Defender, UAC, and SmartScreen',securityCardNote:'Remove Windows Security and Defender, and disable UAC and SmartScreen using bundled third-party rules. Related security policies are changed as well.',securityWarning:'These changes reduce your PC’s protection. There is no reliable automatic undo: create a system image first. Restart Windows manually afterwards.',reviewChanges:'Review changes',serverTitle:'Standard Windows Server uninstall',serverNote:'Uninstall the Windows-Defender Server feature using ServerManager. This method is not available on desktop Windows 10/11.',serverAction:'Uninstall Server feature',securityConfirm:'Change system protections?',securityConfirmNote:'This applies the bundled rules to remove Defender / Windows Security and disable UAC / SmartScreen. VBS, mitigation policies, and other protections are also affected. Back up your system first. Complete removal is not guaranteed.',yesSecurity:'Yes, apply changes',wingetTitle:'WinGet package manager',wingetNote:'WinGet is installed automatically with selected apps. You can also repair it here if app installation is not working.',repairWinget:'Repair WinGet',repairConfirm:'Repair WinGet?',repairNote:'Microsoft.WinGet.Client and WinGet will be installed or updated from Microsoft’s sources. An internet connection is required.',yesRepair:'Yes, repair',activityTitle:'See what’s happening',activityNote:'Operation results and application output from this session.',noActivity:'Your activity will appear here',noActivityNote:'Choose apps to uninstall or install. You can follow every operation here.',running:'In progress',completed:'Completed',attention:'Review results',failed:'Failed',restart:'Restart required',uninstallJob:'Uninstall applications',installJob:'Install applications',repairWingetJob:'Repair WinGet',securityJob:'Change security components',serverSecurityJob:'Uninstall Server Defender',jobCount:'Applications: {n}',waitingLog:'Waiting for application output…',refresh:'Refresh app list',refreshed:'App list refreshed',connectionError:'Could not connect to the application',connectionErrorNote:'Open this interface through Cleanyourwindows.exe. The server may have stopped; launching the EXE again creates a new session.',requestFailed:'Request failed',shutdown:'Application closed. You can close this tab.',lastStatus:'Latest operation',chooseLanguage:'Choose your language'
  }
};

const paths = {
  grid:'<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  trash:'<path d="M3 6h18M9 6V3h6v3M5 6l1 14h12l1-14M10 10v6M14 10v6"/>',
  download:'<path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5"/>',
  shield:'<path d="M12 3 3.5 6v6c0 5 8.5 9 8.5 9s8.5-4 8.5-9V6L12 3Z"/><path d="m8.5 11.5 2.5 2.5 4.5-5"/>',
  activity:'<path d="M3 12h4l3-8 4 16 3-8h4"/>',
  arrow:'<path d="M5 12h14m-5-5 5 5-5 5"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  check:'<path d="m5 12 4 4L19 6"/>',
  search:'<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 4.5 4.5"/>',
  refresh:'<path d="M20 8a8 8 0 1 0 0 8M20 3v5h-5"/>',
  disk:'<rect x="3" y="4" width="18" height="16" rx="3"/><path d="M3 14h18M16 17h2"/>',
  power:'<path d="M12 2v10M6 5a9 9 0 1 0 12 0"/>',
  box:'<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M8 9h8M8 14h5"/>'
};
const icon = name => `<svg viewBox="0 0 24 24" aria-hidden="true">${paths[name] || paths.box}</svg>`;
const badges = {edge:['e','blue'],office:['365','orange'],copilot:['Co','purple'],clipchamp:['Cl','purple'],news:['N','blue'],xbox:['X','green'],teams:['T','purple'],phone:['Ph','blue'],solitaire:['♠','green'],media:['▶','orange'],productivity:['✓','blue'],help:['?','green'],maps:['M','blue'],firefox:['Fx','orange'],vlc:['▶','orange'],obs:['●','purple'],tgwsproxy:['TG','blue'],zapret:['Z','green'],discord:['Di','purple'],vencord:['Ve','purple'],happ:['H','blue'],'7zip':['7z','green'],steam:['St','blue'],prism:['Pr','purple'],codex:['Cx','green'],antigravity:['A','blue'],claude:['Cl','orange'],telegram:['↗','blue'],codexcli:['>_','green']};
const escape = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const badge = id => {const [text,tone] = badges[id] || ['•','green'];return `<span class="app-symbol" data-tone="${tone}">${escape(text)}</span>`;};
let language = localStorage.getItem('clean-language') === 'EN' ? 'EN' : 'RU';
let page = ['overview','uninstall','install','security','activity'].includes(location.hash.slice(1)) ? location.hash.slice(1) : 'overview';
let snapshot = null, query = '', category = 'all', selected = {uninstall:new Set(),install:new Set()}, pending = null, polling = false, connectionFailed = false;
const fragment = new URLSearchParams(location.hash.slice(1));
const token = fragment.get('token') || sessionStorage.getItem('clean-token') || '';
if (fragment.has('token')) {sessionStorage.setItem('clean-token',token);history.replaceState(null,'',`/#${page}`);}
const t = (key, values={}) => (words[language][key] || key).replace(/\{(\w+)\}/g, (_, name) => values[name] ?? `{${name}}`);
const $ = selector => document.querySelector(selector);

async function api(path, body) {
  const options={headers:{'X-Cleanyourwindows-Token':token}};
  if (body !== undefined) {options.method='POST';options.headers['Content-Type']='application/json';options.body=JSON.stringify(body);}
  const response=await fetch(path,options);
  const result=await response.json();
  if (!response.ok) throw new Error(result.error || t('requestFailed'));
  return result;
}
function toast(message,error=false) {const box=$('#toast');box.textContent=message;box.classList.toggle('error',error);box.hidden=false;clearTimeout(toast.timeout);toast.timeout=setTimeout(()=>box.hidden=true,5000);}
function nameOf(app) {return app.name || app[`name${language}`] || app.id;}
function noteOf(app) {return app[`note${language}`] || '';}
function header(title,note) {return `<div class="page-intro"><div><span class="eyebrow">${t('welcome')}</span><h1>${t(title)}</h1><p>${t(note)}</p></div><span class="pill">${icon('box')}${snapshot ? escape(snapshot.catalog.system.caption) : t('thisPC')}</span></div>`;}
function navigate(next) {page=next;query='';category='all';history.replaceState(null,'',`/#${page}`);render();$('#main').focus({preventScroll:true});}
function renderChrome() {
  document.documentElement.lang=language.toLowerCase();
  document.querySelectorAll('[data-i18n]').forEach(node=>node.textContent=t(node.dataset.i18n));
  document.querySelectorAll('[data-language]').forEach(node=>node.classList.toggle('active',node.dataset.language===language));
  $('#breadcrumbPage').textContent=t(page);
  const active = snapshot?.jobs.filter(job=>job.status==='running').length || 0;
  $('#navigation').innerHTML=[['overview','grid'],['uninstall','trash'],['install','download'],['security','shield'],['activity','activity']].map(([id,symbol])=>`<a href="#${id}" class="nav-link ${page===id?'active':''}" data-page="${id}" aria-label="${t(id)}" ${page===id?'aria-current="page"':''}>${icon(symbol)}<span class="nav-label">${t(id)}</span>${id==='activity'&&active?`<span class="nav-counter">${active}</span>`:''}</a>`).join('');
  $('#quitButton').innerHTML=icon('power')+t('quit');
  $('#refreshButton').innerHTML=icon('refresh');$('#refreshButton').title=t('refresh');
  $('#refreshButton').setAttribute('aria-label',t('refresh'));
  $('#connection').classList.toggle('offline',connectionFailed);
  $('#connection').innerHTML=`<i></i><span>${t(connectionFailed?'offline':snapshot?'connected':'connecting')}</span>`;
}
function overview() {
  const {catalog,jobs,busy}=snapshot;
  const detected=catalog.removal.filter(app=>app.detected), free=catalog.disk.free/1024**3,total=catalog.disk.total/1024**3;
  const suggested=['copilot','office','clipchamp','xbox'].map(id=>detected.find(app=>app.id===id)).filter(Boolean);
  const popular=['firefox','discord','7zip','steam','telegram','prism'].map(id=>catalog.installation.find(app=>app.id===id)).filter(Boolean);
  return header('overviewTitle','overviewNote')+`<section class="hero"><div class="hero-copy"><span class="eyebrow">${t('heroLabel')}</span><h2>${t('heroTitle')}</h2><p>${t('heroNote')}</p><div class="hero-actions"><button class="button primary" data-page="uninstall">${icon('trash')}${t('cleanButton')}</button><button class="button subtle" data-page="install">${icon('plus')}${t('installButton')}</button></div></div><div class="hero-art" aria-hidden="true"><span class="art-orbit"></span><span class="art-window"><i></i><i></i><i></i><i></i></span><span class="art-spark">✦</span></div></section>
  <section class="stats"><article class="stat"><div class="stat-top"><span>${t('freeSpace')}</span>${icon('disk')}</div><div class="stat-value">${free.toFixed(1)}<small>GB</small></div><progress value="${Math.round(free)}" max="${Math.round(total)}"></progress><div class="stat-note">${escape(catalog.disk.name)} · ${t('of')} ${total.toFixed(0)} GB</div></article><article class="stat"><div class="stat-top"><span>${t('detectedGroups')}</span>${icon('box')}</div><div class="stat-value">${detected.length}<small>/ ${catalog.removal.length}</small></div><div class="stat-note">${t('detectedNote')}</div></article><article class="stat"><div class="stat-top"><span>${t('sessionActivity')}</span>${icon('activity')}</div><div class="stat-value">${jobs.length.toString().padStart(2,'0')}</div><div class="stat-note">${t(busy?'runningNote':jobs.length?'completed':'noChanges')}</div></article></section>
  <div class="overview-columns"><section><div class="section-heading"><h2>${t('quickCleanup')}</h2><button class="text-link" data-page="uninstall">${t('viewAll')}${icon('arrow')}</button></div><div class="list-panel">${suggested.map(app=>`<div class="mini-app">${badge(app.id)}<div class="mini-app-text"><strong>${escape(nameOf(app))}</strong><p>${escape(noteOf(app))}</p></div><button class="icon-button" data-quick-remove="${app.id}" aria-label="${t('add')}">${icon('plus')}</button></div>`).join('') || `<p class="safe-note">${t('notDetected')}</p>`}</div><div class="safe-note">${icon('shield')}<span>${t('safeNote')}</span></div></section><section><div class="section-heading"><h2>${t('popularApps')}</h2><button class="text-link" data-page="install">${t('viewAll')}${icon('arrow')}</button></div><div class="quick-apps">${popular.map(app=>`<button class="quick-app" data-quick-install="${app.id}">${badge(app.id)}<strong>${escape(app.name)}</strong></button>`).join('')}</div></section></div>`;
}
function appList(mode) {
  let apps=snapshot.catalog[mode==='uninstall'?'removal':'installation'];
  const allApps=apps;
  if (query) apps=apps.filter(app=>(nameOf(app)+' '+noteOf(app)).toLocaleLowerCase().includes(query.toLocaleLowerCase()));
  if (category==='selected') apps=apps.filter(app=>selected[mode].has(app.id));
  else if (mode==='install'&&category!=='all') apps=apps.filter(app=>app.category===category);
  const filters=mode==='install'?['all','browser','media','communication','gaming','coding','network','tools','selectedFilter']:['all','selectedFilter'];
  return header(mode==='install'?'installTitle':'uninstallTitle',mode==='install'?'installNote':'uninstallNote')+`<div class="toolbar"><label class="search">${icon('search')}<input id="appSearch" type="search" autocomplete="off" placeholder="${t('search')}" value="${escape(query)}"></label><div class="selection-tools"><span>${apps.length} / ${allApps.length} ${t('shown')}</span><button data-select-all="${mode}">${t('selectAll')}</button><button data-clear="${mode}">${t('clearSelection')}</button></div></div><div class="filter-row">${filters.map(key=>{const id=key==='selectedFilter'?'selected':key;return `<button class="filter-chip ${category===id?'active':''}" data-filter="${id}">${t(key)}</button>`;}).join('')}</div>
  <section class="app-grid">${apps.map(app=>{const checked=selected[mode].has(app.id),available=mode==='install'||app.detected;return `<button class="app-card ${checked?'selected':''}" data-app="${app.id}" data-mode="${mode}" aria-pressed="${checked}" ${!available||snapshot.busy?'disabled':''}><div class="app-card-top">${badge(app.id)}<span class="check-box">${checked?icon('check'):''}</span></div><h3>${escape(nameOf(app))}</h3><p>${escape(noteOf(app))}</p><span class="card-status ${available?'':'dim'}">${t(mode==='install'?'ready':available?'detected':'notDetected')}</span></button>`;}).join('')}</section>${!apps.length?`<div class="empty-state">${icon('search')}<h2>${t('emptySearch')}</h2><p>${t('emptySearchNote')}</p></div>`:''}`;
}
function security() {return header('securityTitle','securityNote')+`<section class="security-card"><span class="security-icon">${icon('shield')}</span><h2>${t('securityCardTitle')}</h2><p>${t('securityCardNote')}</p><div class="change-tags"><span>Microsoft Defender</span><span>Windows Security</span><span>UAC</span><span>SmartScreen</span><span>VBS / mitigations</span></div><p>${t('securityWarning')}</p><button class="button danger" data-operation="security" ${snapshot.busy?'disabled':''}>${icon('shield')}${t('reviewChanges')}</button></section><section class="security-card secondary"><h2>${t('wingetTitle')}</h2><p>${t('wingetNote')}</p><button class="button" data-operation="repairWinget" ${snapshot.busy?'disabled':''}>${icon('refresh')}${t('repairWinget')}</button></section><section class="security-card secondary"><h2>${t('serverTitle')}</h2><p>${t('serverNote')}</p><button class="button" data-operation="serverSecurity" ${snapshot.busy||!snapshot.catalog.system.serverRemoval?'disabled':''}>${t('serverAction')}</button></section>`;}
function activity() {
  return header('activityTitle','activityNote')+(!snapshot.jobs.length?`<div class="empty-state">${icon('activity')}<h2>${t('noActivity')}</h2><p>${t('noActivityNote')}</p></div>`:[...snapshot.jobs].reverse().map(job=>`<article class="job-card"><div class="job-title"><h3>${t(job.action+'Job')}</h3><span class="status-tag ${escape(job.status)}">${t(job.status)}</span></div><p class="job-date">${escape(new Date(job.started).toLocaleString(language==='RU'?'ru-RU':'en-US'))}${job.ids.length?' · '+t('jobCount',{n:job.ids.length}):''}</p>${job.detail?`<p class="job-detail">${escape(job.detail)}</p>`:''}<pre class="job-log">${escape(job.logs.length?job.logs.join('\n'):t('waitingLog'))}</pre></article>`).join(''));
}
function renderDock() {
  const dock=$('#selectionDock'),items=selected[page];
  if (!items||!items.size||!snapshot) {dock.hidden=true;return;}
  dock.hidden=false;dock.innerHTML=`<div><div class="dock-title">${t('selectedCount',{n:items.size})}</div><div class="dock-note">${t(page==='install'?'dockInstall':'dockRemove')}</div></div><div class="dock-actions"><button class="dock-clear" data-clear="${page}">${t('clearSelection')}</button><button class="button primary" id="reviewButton" ${snapshot.busy?'disabled':''}>${t('review')}${icon('arrow')}</button></div>`;
}
function render() {
  const searchFocused=document.activeElement?.id==='appSearch';
  const searchPosition=searchFocused?document.activeElement.selectionStart:null;
  renderChrome();
  if (!snapshot) {renderDock();return;}
  let html=snapshot.catalog.demo?`<div class="demo-strip">${t('demo')}</div>`:'';
  html+=page==='overview'?overview():page==='uninstall'||page==='install'?appList(page):page==='security'?security():activity();
  $('#main').innerHTML=html;renderDock();
  if(searchFocused&&$('#appSearch')) {$('#appSearch').focus();try{$('#appSearch').setSelectionRange(searchPosition,searchPosition);}catch{}}
}
async function refreshState(initial=false) {
  if (polling) return;polling=true;
  try {
    const next=await api('/api/state');
    const changed=JSON.stringify(snapshot)!==JSON.stringify(next);
    snapshot=next;connectionFailed=false;
    if (initial||changed||$('#main').querySelector('.error-state')) render(); else renderChrome();
  } catch (error) {
    connectionFailed=true;renderChrome();
    if (!snapshot) $('#main').innerHTML=`<div class="error-state"><h2>${t('connectionError')}</h2><p>${t('connectionErrorNote')}</p><p>${escape(error.message)}</p></div>`;
  } finally {polling=false;}
}
async function confirmOperation(action,ids=[]) {
  if (snapshot?.busy) return toast(t('busy'),true);
  pending={action,ids,language};
  try {
    const plan=await api('/api/plan',pending);
    let title='confirmRemove',note='confirmNoteRemove',yes='yesRemove',danger=false;
    if (action==='install') {title='confirmInstall';note='confirmNoteInstall';yes='yesInstall';}
    if (action==='security'||action==='serverSecurity') {title='securityConfirm';note='securityConfirmNote';yes='yesSecurity';danger=true;}
    if (action==='repairWinget') {title='repairConfirm';note='repairNote';yes='yesRepair';}
    $('#dialogContent').innerHTML=`<div class="dialog-inner"><span class="eyebrow">CLEANYOURWINDOWS</span><h2 id="dialogTitle">${t(title)}</h2><p>${t(note)}</p>${plan.items.length?`<ul class="dialog-list">${plan.items.map(app=>`<li>${escape(app.name)}${app.dependency?`<span class="dependency">${t('dependency')}</span>`:''}</li>`).join('')}</ul>`:''}${danger?`<div class="dialog-warning">${t('securityWarning')}</div>`:''}${snapshot.catalog.demo?`<p>${t('demo')}</p>`:''}<div class="dialog-actions"><button class="button" id="cancelConfirm">${t('cancel')}</button><button class="button ${danger?'danger':'primary'}" id="acceptConfirm">${t(yes)}</button></div></div>`;
    $('#confirmDialog').showModal();
  } catch(error) {toast(error.message,true);}
}
async function runConfirmed() {
  if (!pending) return;
  const button=$('#acceptConfirm');button.disabled=true;button.textContent=t('starting');
  try {
    await api('/api/run',{...pending,confirmed:true});
    if (selected[pending.action]) selected[pending.action].clear();
    pending=null;$('#confirmDialog').close();navigate('activity');toast(t('operationStarted'));await refreshState(true);
  } catch(error) {toast(error.message,true);button.disabled=false;button.textContent=t('review');}
}
function changeLanguage(next) {language=next;localStorage.setItem('clean-language',language);$('#toast').hidden=true;render();}

document.addEventListener('click',event=>{
  const node=event.target.closest('button,a');if(!node) return;
  if(node.dataset.page) {event.preventDefault();navigate(node.dataset.page);}
  if(node.dataset.language) changeLanguage(node.dataset.language);
  if(node.dataset.initialLanguage) {changeLanguage(node.dataset.initialLanguage);$('#languageDialog').close();}
  if(node.dataset.quickRemove) {selected.uninstall.add(node.dataset.quickRemove);navigate('uninstall');}
  if(node.dataset.quickInstall) {selected.install.add(node.dataset.quickInstall);navigate('install');}
  if(node.dataset.app) {const set=selected[node.dataset.mode];set.has(node.dataset.app)?set.delete(node.dataset.app):set.add(node.dataset.app);render();}
  if(node.dataset.filter) {category=node.dataset.filter;render();}
  if(node.dataset.clear) {selected[node.dataset.clear].clear();render();}
  if(node.dataset.selectAll&&snapshot) {const mode=node.dataset.selectAll;for(const app of snapshot.catalog[mode==='install'?'installation':'removal']) if(mode==='install'||app.detected) selected[mode].add(app.id);render();}
  if(node.id==='reviewButton') confirmOperation(page,[...selected[page]]);
  if(node.dataset.operation) confirmOperation(node.dataset.operation);
  if(node.id==='cancelConfirm') {pending=null;$('#confirmDialog').close();}
  if(node.id==='acceptConfirm') runConfirmed();
});
document.addEventListener('input',event=>{
  if(event.target.id!=='appSearch') return;
  const position=event.target.selectionStart;query=event.target.value;render();
  const input=$('#appSearch');input.focus();try{input.setSelectionRange(position,position);}catch{}
});
$('#refreshButton').addEventListener('click',async()=>{try{await api('/api/refresh',{});await refreshState(true);toast(t('refreshed'));}catch(error){toast(error.message,true);}});
$('#quitButton').addEventListener('click',async()=>{try{await api('/api/shutdown',{});toast(t('shutdown'));clearInterval(timer);$('#connection').classList.add('offline');}catch(error){toast(error.message,true);}});
$('#confirmDialog').addEventListener('cancel',()=>pending=null);
renderChrome();
if(!localStorage.getItem('clean-language')) $('#languageDialog').showModal();
refreshState(true);
const timer=setInterval(()=>refreshState(),1500);
