/* DocSafe – maquettes : composants communs.
   Chaque fonction renvoie du HTML. Les écrans (screens-1.js, screens-2.js) les assemblent.
   Ces composants correspondent aux widgets réutilisables décrits dans docs/07-design.md. */
(function () {
  'use strict';

  /* ---------- Icônes ---------- */
  const ICONS = window.DS_ICONS || {};
  const sprite = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  sprite.setAttribute('aria-hidden', 'true');
  sprite.setAttribute('style', 'position:absolute;width:0;height:0;overflow:hidden');
  sprite.innerHTML = Object.keys(ICONS)
    .map((k) => `<symbol id="i-${k}" viewBox="0 -960 960 960">${ICONS[k]}</symbol>`)
    .join('');
  document.body.insertBefore(sprite, document.body.firstChild);

  const missing = new Set();
  const I = (name, cls) => {
    if (!ICONS[name]) missing.add(name);
    return `<svg class="ic${cls ? ' ' + cls : ''}" aria-hidden="true"><use href="#i-${name}"/></svg>`;
  };

  /* ---------- Logo ---------- */
  const logo = (size) =>
    `<svg width="${size || 32}" height="${size || 32}" viewBox="0 0 48 48" role="img" aria-label="DocSafe" style="flex:none;display:block">` +
    '<rect width="48" height="48" rx="12" fill="#205DB0"/>' +
    '<path d="M16 9.5h11.2l8.3 8.3V36a2.5 2.5 0 0 1-2.5 2.5H16a2.5 2.5 0 0 1-2.5-2.5V12A2.5 2.5 0 0 1 16 9.5Z" fill="#fff"/>' +
    '<path d="M27.2 9.5v5.8a2.5 2.5 0 0 0 2.5 2.5h5.8Z" fill="#ABC7FF"/>' +
    '<circle cx="24.5" cy="25.6" r="3.5" fill="#205DB0"/>' +
    '<path d="M23 27.6h3l1.2 6.2h-5.4Z" fill="#205DB0"/></svg>';

  /* ---------- Données d'exemple (maquettes uniquement) ---------- */
  const CATS = {
    identite: { n: 'Identité', ic: 'badge', c: 'blue', count: 14 },
    education: { n: 'Éducation', ic: 'school', c: 'purple', count: 22 },
    pro: { n: 'Professionnel', ic: 'work', c: 'teal', count: 31 },
    finances: { n: 'Finances', ic: 'account_balance_wallet', c: 'green', count: 38 },
    immo: { n: 'Immobilier', ic: 'home_work', c: 'orange', count: 9 },
    sante: { n: 'Santé', ic: 'medical_services', c: 'pink', count: 11 },
    autres: { n: 'Autres', ic: 'folder', c: 'slate', count: 3 },
  };
  const DOCS = {
    passeport: { t: 'Passeport', cat: 'identite', fmt: 'PDF', pages: 2, th: 'id' },
    visa: { t: 'Visa Schengen', cat: 'identite', fmt: 'JPEG', th: 'id' },
    permis: { t: 'Permis de conduire', cat: 'identite', fmt: 'PDF', pages: 2, th: 'id' },
    electeur: { t: 'Carte d’électeur', cat: 'identite', fmt: 'JPEG', th: 'id' },
    diplome: { t: 'Diplôme de licence', cat: 'education', fmt: 'PDF', pages: 1, th: 'cert' },
    releve: { t: 'Relevé de notes – L3', cat: 'education', fmt: 'PDF', pages: 3, th: 'doc' },
    contrat: { t: 'Contrat de travail', cat: 'pro', fmt: 'PDF', pages: 6, th: 'letter' },
    facture: { t: 'Facture d’électricité – oct.', cat: 'finances', fmt: 'PDF', pages: 1, th: 'invoice' },
    bail: { t: 'Contrat de bail', cat: 'immo', fmt: 'PDF', pages: 8, th: 'letter' },
    assurance: { t: 'Assurance habitation', cat: 'immo', fmt: 'PDF', pages: 4, th: 'doc' },
    vaccin: { t: 'Carnet de vaccination', cat: 'sante', fmt: 'JPEG', th: 'photo' },
  };

  /* ---------- Structure d'un écran ---------- */
  const statusBar = () =>
    `<div class="sb"><span>9:41</span><span class="sb-i">${I('signal_cellular_alt-fill')}${I('wifi-fill')}${I('battery_full-fill')}</span></div>`;
  const gesture = (cls) => `<div class="gesture ${cls || ''}"><i></i></div>`;

  const appBar = (o) => {
    const lead = o.back ? `<span class="iconbtn">${I('arrow_back')}</span>` : o.close ? `<span class="iconbtn">${I('close')}</span>` : '';
    const title = o.brand
      ? `<div class="brand">${logo(32)}<span>DocSafe</span></div>`
      : `<div class="title${lead ? ' after-lead' : ''}">${o.title || ''}</div>`;
    const actions = (o.actions || []).map((a) => (a.charAt(0) === '<' ? a : `<span class="iconbtn">${I(a)}</span>`)).join('');
    return `<div class="appbar">${lead}${title}${actions}</div>`;
  };

  const NAV = [
    ['home', 'Accueil', 'home'],
    ['docs', 'Documents', 'folder'],
    ['scan', 'Scanner', 'document_scanner'],
    ['dead', 'Échéances', 'event'],
    ['set', 'Paramètres', 'settings'],
  ];
  const navBar = (active) =>
    `<nav class="nav">${NAV.map(([id, label, ic]) => {
      const on = id === active;
      return `<a class="${on ? 'on ' : ''}${id === 'scan' ? 'scan' : ''}"><span class="pill">${I(on || id === 'scan' ? ic + '-fill' : ic)}</span>${label}</a>`;
    }).join('')}</nav>`;

  /* phone({ app, body, nav, fab, overlay, cls, bodyCls, dark }) */
  const phone = (o) =>
    `<div class="phone"><div class="screen ${o.cls || ''}"${o.dark ? ' data-theme="dark"' : ''}>` +
    statusBar() +
    (o.app ? appBar(o.app) : '') +
    `<div class="body ${o.bodyCls || ''}">${o.body || ''}${o.fab || ''}</div>` +
    (o.nav ? navBar(o.nav) : '') +
    gesture(o.nav ? 'on-nav' : '') +
    (o.overlay || '') +
    '</div></div>';

  /* ---------- Composants ---------- */
  const btn = (label, kind, icon) => `<span class="btn ${kind || 'filled'}${icon ? ' has-ic' : ''}">${icon ? I(icon) : ''}${label}</span>`;
  const chip = (label, o) => {
    o = o || {};
    const lead = o.on ? I('check') : o.icon ? I(o.icon) : '';
    return `<span class="chip${o.on ? ' on' : ''}${lead ? ' has-ic' : ''}${o.trail ? ' has-trail' : ''}${o.sm ? ' sm' : ''}">${lead}${label}${o.trail ? I(o.trail) : ''}</span>`;
  };
  const badge = (label, kind, icon) => `<span class="badge ${kind || ''}">${icon ? I(icon) : ''}${label}</span>`;
  const sw = (on) => `<span class="switch${on ? ' on' : ''}"></span>`;
  const cat = (key, size) => `<span class="cat c-${CATS[key].c} ${size || ''}">${I(CATS[key].ic)}</span>`;
  const lead = (icon) => `<span class="lead">${I(icon)}</span>`;
  const chev = () => I('chevron_right');
  const section = (title, action) => `<div class="sec"><h4>${title}</h4>${action ? `<a>${action}</a>` : ''}</div>`;

  const field = (label, value, o) => {
    o = o || {};
    const inner = value
      ? `<span class="v">${value}${o.focus ? '<span class="caret"></span>' : ''}</span>`
      : `<span class="ph">${o.ph || ''}</span>`;
    return `<div class="field${o.focus ? ' focus' : ''}${o.area ? ' area' : ''}${o.mono ? ' mono' : ''}"><label>${label}</label>${o.lead ? I(o.lead) : ''}${inner}${o.trail ? I(o.trail) : ''}</div>`;
  };

  const tile = (o) =>
    `<div class="tile${o.sub ? ' two' : ''} ${o.cls || ''}">${o.lead || ''}<div class="tx"><div class="t1">${o.title}</div>` +
    (o.sub ? `<div class="t2${o.wrap ? ' wrap' : ''}">${o.sub}</div>` : '') +
    `</div>${o.trail ? `<div class="trail">${o.trail}</div>` : ''}</div>`;

  /* Miniature de document dessinée (dans l'application : première page réelle, déchiffrée à l'affichage). */
  const BARS = {
    doc: [100, 92, 100, 84, 100, 96, 62],
    letter: [42, 100, 96, 100, 90, 100, 54],
    id: [100, 78, 100, 62, 88],
    cert: [72, 88, 58, 80, 46],
    invoice: [100, 100, 100, 100, 100, 70],
  };
  const thumb = (kind, size) => {
    kind = kind || 'doc';
    size = size || '';
    if (kind === 'photo') return `<span class="thumb photo ${size}"></span>`;
    const repeat = size === 'page' ? 3 : size === 'lg' || size === 'xl' ? 2 : 1;
    let bars = [];
    for (let i = 0; i < repeat; i++) bars = bars.concat(BARS[kind] || BARS.doc);
    const extra = kind === 'id' ? '<span class="av"></span>' : kind === 'cert' ? '<span class="seal"></span>' : kind === 'invoice' ? '<span class="tot"></span>' : '';
    return `<span class="thumb ${kind} ${size}"><span class="in"><b class="h" style="width:${kind === 'cert' ? 64 : 55}%"></b>${bars
      .map((w) => `<b style="width:${w}%"></b>`)
      .join('')}</span>${extra}</span>`;
  };

  const docSub = (d) => `${CATS[d.cat].n} · ${d.fmt}${d.pages ? ' · ' + d.pages + (d.pages > 1 ? ' pages' : ' page') : ''}`;
  const docTile = (key, o) => {
    o = o || {};
    const d = DOCS[key];
    return tile({ lead: thumb(d.th), title: o.title || d.t, sub: o.sub || docSub(d), trail: o.trail, cls: o.cls });
  };

  const dots = (filled, total, err) =>
    `<div class="dots${err ? ' err' : ''}">${Array.from({ length: total || 6 }, (_, k) => `<i class="${k < filled ? 'on' : ''}"></i>`).join('')}</div>`;
  const keypad = (o) => {
    o = o || {};
    return (
      `<div class="keypad${o.off ? ' off' : ''}">` +
      [1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => `<span class="key">${n}</span>`).join('') +
      `<span class="key ghost">${o.bio ? I('fingerprint') : ''}</span><span class="key">0</span><span class="key ghost">${I('backspace')}</span></div>`
    );
  };

  /* ---------- Registre des écrans et affichage ---------- */
  const GROUPS = [];
  const group = (id, title, desc) => {
    const g = { id, title, desc, frames: [] };
    GROUPS.push(g);
    return g;
  };
  const frame = (g, num, title, note, html) => g.frames.push({ num, title, note, html });

  const setTheme = (t) => {
    document.documentElement.setAttribute('data-theme', t);
    document.querySelectorAll('[data-set-theme]').forEach((b) => b.setAttribute('aria-pressed', String(b.getAttribute('data-set-theme') === t)));
    try { localStorage.setItem('docusafe-maquettes-theme', t); } catch (e) { /* stockage indisponible : sans conséquence */ }
  };

  const render = () => {
    const params = new URLSearchParams(location.search);
    const only = params.get('only');
    if (params.get('bare')) document.body.classList.add('bare');

    let theme = params.get('theme');
    if (!theme) { try { theme = localStorage.getItem('docusafe-maquettes-theme'); } catch (e) { theme = null; } }
    setTheme(theme === 'dark' ? 'dark' : 'light');
    document.querySelectorAll('[data-set-theme]').forEach((b) => b.addEventListener('click', () => setTheme(b.getAttribute('data-set-theme'))));

    const shown = GROUPS.filter((g) => !only || only.split(',').indexOf(g.id) >= 0);
    const toc = document.getElementById('toc');
    if (toc) toc.innerHTML = GROUPS.map((g) => `<a href="#${g.id}">${g.title}</a>`).join('');
    const total = GROUPS.reduce((n, g) => n + g.frames.length, 0);
    const counter = document.getElementById('count');
    if (counter) counter.textContent = total + ' écrans';

    document.getElementById('app').innerHTML = shown
      .map(
        (g) =>
          `<section class="group" id="${g.id}"><h2>${g.title}</h2><p>${g.desc}</p><div class="frames">` +
          g.frames.map((f) => `<figure><figcaption><b>${f.num} · ${f.title}</b><span>${f.note || ''}</span></figcaption>${f.html}</figure>`).join('') +
          '</div></section>'
      )
      .join('');

    if (missing.size) console.warn('Icônes manquantes :', Array.from(missing).join(', '));
    document.documentElement.setAttribute('data-ready', missing.size ? 'missing:' + Array.from(missing).join(',') : 'ok');
  };

  window.UI = { I, logo, phone, btn, chip, badge, sw, cat, lead, chev, section, field, tile, thumb, docTile, dots, keypad, CATS, DOCS };
  window.DS = { group, frame, render, parts: {} };
})();
