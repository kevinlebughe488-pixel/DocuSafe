/* DocuSafe – maquettes, écrans 1 à 10 : démarrage, déverrouillage, accueil, documents, ajout. */
(function () {
  'use strict';
  const { I, logo, phone, btn, chip, badge, cat, section, field, tile, thumb, docTile, dots, keypad, CATS, DOCS } = window.UI;
  const DS = window.DS;

  /* =====================================================================
     1. Démarrage et création du coffre
     ===================================================================== */
  const g1 = DS.group('g1', '1. Démarrage et création du coffre',
    'Première ouverture. Aucun compte, aucune connexion : l’utilisateur découvre DocuSafe, choisit son code, note sa clé de récupération, puis active la biométrie s’il le souhaite.');

  DS.frame(g1, '1', 'Écran de démarrage', 'Visible moins d’une seconde, le temps de préparer l’application.', phone({
    body: `<div class="empty">${logo(96)}<div class="t-hm w500 mt24">DocuSafe</div><p class="mt8">Vos documents, protégés.</p></div>
      <div class="center mb16"><span class="secure-line">${I('lock-fill')}Chiffré sur cet appareil</span></div>`,
  }));

  const onboarding = (index, icon, orbA, orbB, title, text) => {
    const last = index === 3;
    return phone({
      body: `<div class="row pad" style="height:56px;justify-content:flex-end">${last ? '' : btn('Passer', 'text')}</div>
        <div class="col grow pad center" style="justify-content:center">
          <div class="illus big">${I(icon)}<span class="orb a">${I(orbA)}</span><span class="orb b">${I(orbB)}</span></div>
          <div class="t-hs mt32">${title}</div>
          <p class="t-bl muted mt12" style="margin-bottom:0">${text}</p>
          ${last ? '<p class="t-bm mt16" style="margin-bottom:0"><a class="c-primary w500">Politique de confidentialité</a> · <a class="c-primary w500">Conditions d’utilisation</a></p>' : ''}
        </div>
        <div class="pad col g24" style="padding-bottom:16px">
          <div class="pager">${[0, 1, 2, 3].map((k) => `<i class="${k === index ? 'on' : ''}"></i>`).join('')}</div>
          ${last ? btn('Créer mon coffre-fort', 'filled lg block', 'lock') : btn('Suivant', 'filled lg block')}
        </div>`,
    });
  };
  DS.frame(g1, '2a', 'Onboarding – bienvenue', 'Quatre pages courtes. « Passer » mène directement à la création du coffre.',
    onboarding(0, 'shield_lock', 'description', 'fingerprint', 'Bienvenue dans DocuSafe',
      'Le coffre-fort de vos documents importants : pièces d’identité, diplômes, contrats, factures.'));
  DS.frame(g1, '2b', 'Onboarding – stockage local', 'Explique le fonctionnement hors ligne.',
    onboarding(1, 'smartphone', 'wifi_off', 'cloud_off', 'Tout reste sur votre téléphone',
      'Pas de compte à créer, pas de serveur. DocuSafe fonctionne sans connexion Internet.'));
  DS.frame(g1, '2c', 'Onboarding – sécurité', 'Explique le chiffrement en mots simples.',
    onboarding(2, 'encrypted', 'pin', 'fingerprint', 'Chiffré et protégé par votre code',
      'Chaque document est chiffré. Sans votre code ou votre empreinte, personne ne peut le lire.'));
  DS.frame(g1, '2d', 'Onboarding – confidentialité', 'Liens vers les textes légaux, puis création du coffre.',
    onboarding(3, 'verified_user', 'visibility_off', 'block', 'Vos documents vous appartiennent',
      'Aucune publicité, aucun suivi. Rien ne quitte votre téléphone sans votre accord.'));

  const stepHead = (n, title, text) =>
    `<div class="pad"><div class="row g12"><span class="t-lm muted" style="white-space:nowrap">Étape ${n} sur 3</span><div class="linear grow"><i style="width:${Math.round(n * 33.4)}%"></i></div></div>
      <div class="t-hs mt24">${title}</div><p class="t-bm muted mt8" style="margin-bottom:0">${text}</p></div>`;

  DS.frame(g1, '3a', 'Création du code', 'Six chiffres au minimum. Un second écran identique demande de le confirmer.', phone({
    app: { back: true },
    body: `${stepHead(1, 'Choisissez votre code', '6 chiffres ou plus. Ce code protège tous vos documents.')}
      <div class="col grow" style="justify-content:center">${dots(3)}</div>
      <div class="col g12" style="padding-bottom:16px">${keypad()}<p class="t-bs muted center" style="margin:4px 0 0">Évitez les suites simples comme 123456.</p></div>`,
  }));

  DS.frame(g1, '3b', 'Clé de récupération', 'Affichée une seule fois. La case doit être cochée pour continuer.', phone({
    app: { back: true },
    body: `${stepHead(2, 'Votre clé de récupération', 'Elle permet de retrouver l’accès si vous oubliez votre code. Notez-la et gardez-la ailleurs que sur ce téléphone.')}
      <div class="pad col g12 mt16">
        <div class="keybox">7K3M-Q9XD-2HFP-W8TN<br>4RJC-6YBE-ZV5G-A1S0</div>
        <div class="row" style="justify-content:center">${btn('Copier', 'tonal', 'content_copy')}</div>
        <div class="banner warn">${I('warning-fill')}<span>Sans votre code et sans cette clé, vos documents seront <b>définitivement perdus</b>. Personne ne pourra les récupérer.</span></div>
      </div>
      <div class="pad col g16 mt-auto" style="padding-bottom:16px">
        <div class="row g12"><span class="check on">${I('check')}</span><span class="t-bm">J’ai conservé ma clé en lieu sûr</span></div>
        ${btn('Continuer', 'filled lg block')}
      </div>`,
  }));

  DS.frame(g1, '3c', 'Biométrie (facultatif)', 'Proposée uniquement si le téléphone le permet.', phone({
    app: { back: true },
    body: `${stepHead(3, 'Déverrouiller plus vite ?', 'Utilisez votre empreinte pour ouvrir DocuSafe. Votre code reste toujours valable.')}
      <div class="col grow" style="justify-content:center"><div class="illus big sec">${I('fingerprint')}</div></div>
      <div class="pad col g8" style="padding-bottom:16px">${btn('Activer l’empreinte', 'filled lg block', 'fingerprint')}${btn('Plus tard', 'text block')}</div>`,
  }));

  /* =====================================================================
     2. Déverrouillage
     ===================================================================== */
  const g2 = DS.group('g2', '2. Déverrouillage',
    'À chaque ouverture et après chaque verrouillage automatique. Le clavier est dessiné par l’application : ce n’est pas celui du téléphone.');

  DS.frame(g2, '4a', 'Déverrouillage', 'Si la biométrie est activée, la fenêtre du système s’ouvre d’abord toute seule.', phone({
    body: `<div class="col" style="align-items:center;padding-top:36px">${logo(56)}<div class="t-tl mt16">Saisissez votre code</div></div>
      <div class="col grow" style="justify-content:center">${dots(2)}</div>
      <div class="col g8" style="padding-bottom:8px">${keypad({ bio: true })}<div class="row" style="justify-content:center">${btn('Code oublié ?', 'text')}</div></div>`,
  }));

  DS.frame(g2, '4b', 'Trop d’essais', 'Après 5 erreurs : attente croissante (30 s, 1 min, 5 min…). Le clavier est désactivé.', phone({
    body: `<div class="col" style="align-items:center;padding-top:36px">${logo(56)}<div class="t-tl mt16">Trop d’essais</div>
        <p class="t-bm muted center" style="margin:4px 32px 0">Par sécurité, patientez avant de réessayer.</p></div>
      <div class="col grow g16" style="justify-content:center;align-items:center">${dots(0, 6, true)}
        <span class="badge err" style="height:32px;padding:0 12px;font-size:14px;line-height:20px">${I('timer')}Réessayez dans 28 s</span></div>
      <div class="col g8" style="padding-bottom:8px">${keypad({ off: true })}<div class="row" style="justify-content:center">${btn('Utiliser ma clé de récupération', 'text')}</div></div>`,
  }));

  DS.frame(g2, '4c', 'Code oublié', 'La clé de récupération rouvre le coffre, puis l’utilisateur choisit un nouveau code.', phone({
    app: { back: true, title: 'Code oublié' },
    body: `<div class="pad col g16">
        <p class="t-bm muted" style="margin:0">Saisissez la clé de récupération affichée à la création de votre coffre.</p>
        ${field('Clé de récupération', '7K3M-Q9XD-2HFP-W8TN-4R', { focus: true, mono: true })}
        <div class="helper" style="margin-top:-12px">18 caractères sur 32</div>
        <div class="banner info">${I('info')}<span>Vous choisirez ensuite un nouveau code. Vos documents ne changent pas.</span></div>
      </div>
      <div class="pad mt-auto" style="padding-bottom:16px">${btn('Vérifier la clé', 'off lg block')}</div>`,
  }));

  /* =====================================================================
     3. Accueil
     ===================================================================== */
  const g3 = DS.group('g3', '3. Accueil (tableau de bord)',
    'Écran principal. Il est composé de sections indépendantes : elles pourront être réorganisées dans une version future.');

  const brandBar = { brand: true, actions: ['lock'] };

  DS.frame(g3, '5a', 'Tableau de bord', 'Compteur, recherche, accès rapides, prochaines échéances, catégories. Le cadenas verrouille tout de suite.', phone({
    app: brandBar, nav: 'home',
    body: `<div class="pad"><div class="t-hs">128 documents</div><span class="secure-line mt4">${I('lock-fill')}Chiffrés sur cet appareil · 312 Mo</span></div>
      <div class="pad mt16"><div class="searchbar">${I('search')}<span class="ph">Rechercher un document</span></div></div>
      <div class="pad row g8 mt16">${btn('Scanner', 'filled flex1', 'document_scanner')}${btn('Importer', 'tonal flex1', 'upload_file')}</div>
      ${section('Échéances à venir', 'Tout voir')}
      <div class="pad"><div class="card flush">
        ${docTile('visa', { sub: 'Expire le 20 nov. 2026', trail: badge('J-7', 'warn') })}
        ${docTile('assurance', { sub: 'Expire le 1er déc. 2026', trail: badge('J-18', 'warn') })}
      </div></div>
      ${section('Catégories', 'Gérer')}
      <div class="hscroll">${['identite', 'education', 'pro', 'finances'].map((k) => `<div class="cat-card">${cat(k)}<b>${CATS[k].n}</b><span>${CATS[k].count} documents</span></div>`).join('')}</div>`,
  }));

  DS.frame(g3, '5b', 'Tableau de bord (suite)', 'Ce qui apparaît en faisant défiler : favoris et documents ajoutés récemment.', phone({
    app: brandBar, nav: 'home',
    body: `${section('Favoris', 'Tout voir')}
      <div class="hscroll" style="gap:12px">${['passeport', 'diplome', 'contrat'].map((k) => `<div class="doc-card"><div class="frame">${thumb(DOCS[k].th, 'lg')}${I('star-fill', 'star')}</div><b>${DOCS[k].t}</b><span>${CATS[DOCS[k].cat].n}</span></div>`).join('')}</div>
      ${section('Ajoutés récemment', 'Tout voir')}
      ${docTile('bail', { trail: '<span>Aujourd’hui</span>' })}
      ${docTile('facture', { trail: '<span>Hier</span>' })}
      ${docTile('releve', { trail: '<span>10 nov.</span>' })}
      ${docTile('vaccin', { trail: '<span>8 nov.</span>' })}`,
  }));

  DS.frame(g3, '5c', 'Tableau de bord vide', 'Juste après la création du coffre : deux actions bien visibles.', phone({
    app: brandBar, nav: 'home',
    body: `<div class="empty"><div class="illus big">${I('inventory_2')}</div><h3>Votre coffre est vide</h3>
      <p>Numérisez ou importez votre premier document. Il sera chiffré sur ce téléphone.</p>
      <div class="col g8 mt24" style="width:100%">${btn('Scanner un document', 'filled lg block', 'document_scanner')}${btn('Importer un fichier', 'tonal lg block', 'upload_file')}</div></div>`,
  }));

  /* =====================================================================
     4. Documents
     ===================================================================== */
  const g4 = DS.group('g4', '4. Documents',
    'Liste, favoris, récents, fiche d’un document, lecture, modification et suppression.');

  const docTabs = (on) => `<div class="tabs">${['Tous', 'Favoris', 'Récents'].map((t, k) => `<a class="${k === on ? 'on' : ''}">${t}</a>`).join('')}</div>`;
  const star = I('star-fill', 'c-primary');
  const listBar = { title: 'Documents', actions: ['search', 'swap_vert'] };
  const addFab = `<span class="fab">${I('add')}</span>`;

  DS.frame(g4, '6', 'Liste des documents', 'Filtre par catégorie, tri, recherche. Le bouton + propose : scanner, importer un fichier, importer des photos.', phone({
    app: listBar, nav: 'docs', bodyCls: 'fade', fab: addFab,
    body: `${docTabs(0)}
      <div class="chips pad" style="padding-top:12px;padding-bottom:4px">${chip('Toutes', { on: true })}${chip('Identité')}${chip('Éducation')}${chip('Professionnel')}</div>
      ${docTile('bail')}
      ${docTile('facture')}
      ${docTile('passeport', { trail: star })}
      ${docTile('visa', { trail: badge('J-7', 'warn') })}
      ${docTile('diplome', { trail: star })}
      ${docTile('permis', { trail: badge('Expiré', 'err') })}
      ${docTile('contrat', { trail: star })}`,
  }));

  DS.frame(g4, '13', 'Favoris', 'Les documents les plus utilisés, accessibles en un geste.', phone({
    app: listBar, nav: 'docs', fab: addFab,
    body: `${docTabs(1)}<div style="height:8px"></div>
      ${docTile('passeport', { trail: star })}
      ${docTile('diplome', { trail: star })}
      ${docTile('contrat', { trail: star })}
      ${docTile('electeur', { trail: star })}`,
  }));

  DS.frame(g4, '14', 'Récents', 'Deux vues : ajoutés récemment ou consultés récemment.', phone({
    app: listBar, nav: 'docs', fab: addFab,
    body: `${docTabs(2)}
      <div class="pad" style="padding-top:12px;padding-bottom:8px"><div class="seg"><a>Ajoutés</a><a class="on">${I('check')}Consultés</a></div></div>
      ${docTile('passeport', { sub: 'Consulté aujourd’hui à 09:12' })}
      ${docTile('visa', { sub: 'Consulté aujourd’hui à 08:47' })}
      ${docTile('bail', { sub: 'Consulté hier' })}
      ${docTile('facture', { sub: 'Consulté le 10 nov.' })}
      ${docTile('diplome', { sub: 'Consulté le 6 nov.' })}`,
  }));

  const detailBody = `<div class="preview">${thumb('id', 'xl')}<span class="badge count">2 pages</span></div>
      <div class="pad mt16"><div class="t-hs">Passeport</div>
        <div class="chips mt8">${chip('Identité', { icon: 'badge' })}${chip('PDF · 1,2 Mo', { icon: 'picture_as_pdf' })}</div></div>
      <div class="pad row g8 mt16">${btn('Ouvrir', 'filled flex1', 'description')}${btn('Partager', 'tonal flex1', 'share')}${btn('Exporter', 'tonal flex1', 'download')}</div>
      <div style="height:8px"></div>
      <div class="kv"><span class="k">Expiration</span><span class="v">14 févr. 2027 ${badge('dans 3 mois')}</span><span class="muted">${I('chevron_right')}</span></div>
      <div class="kv"><span class="k">Émission</span><span class="v">15 févr. 2017</span></div>
      <div class="kv"><span class="k">Type</span><span class="v">Passeport</span></div>
      <div class="kv"><span class="k">Tags</span><span class="v">${chip('voyage', { sm: true })}${chip('officiel', { sm: true })}</span></div>
      <div class="kv"><span class="k">Ajouté le</span><span class="v">12 nov. 2026</span></div>
      <div class="pad" style="padding-top:6px"><span class="secure-line">${I('verified_user-fill')}Chiffré · intégrité vérifiée</span></div>`;
  const detailBar = { back: true, actions: [`<span class="iconbtn on">${I('star-fill')}</span>`, 'more_vert'] };
  DS.parts.detailBody = detailBody;
  DS.parts.detailBar = detailBar;

  DS.frame(g4, '7', 'Fiche d’un document', 'Toucher « Expiration » ouvre les rappels. Le menu ⋮ contient : modifier, déplacer, supprimer.', phone({
    app: detailBar, body: detailBody,
  }));

  DS.frame(g4, '7b', 'Lecture', 'Toujours sur fond sombre. Le document est déchiffré à ce moment-là seulement, puis son intégrité est vérifiée.', phone({
    cls: 'viewer', dark: true,
    app: { back: true, title: 'Passeport', actions: ['share', 'more_vert'] },
    body: `${thumb('id', 'page')}<span class="pill">1 / 2</span>`,
  }));

  const editBody = `<div class="pad col g24" style="padding-top:12px">
        ${field('Nom', 'Passeport', { focus: true })}
        ${field('Catégorie', 'Identité', { trail: 'expand_more' })}
        ${field('Type de document', 'Passeport')}
        ${field('Date d’émission', '15/02/2017', { trail: 'calendar_month' })}
        ${field('Date d’expiration', '14/02/2027', { trail: 'calendar_month' })}
        <div class="field tagfield"><label>Tags</label>${chip('voyage', { trail: 'close' })}${chip('officiel', { trail: 'close' })}<span class="ph">Ajouter…</span></div>
        ${field('Description', '', { area: true, ph: 'Facultatif' })}
      </div>`;
  const editBar = { close: true, title: 'Modifier', actions: ['<span class="btn text">Enregistrer</span>'] };
  DS.parts.editBody = editBody;
  DS.parts.editBar = editBar;

  DS.frame(g4, '7c', 'Modification', 'Les tags déjà utilisés sont proposés pendant la saisie.', phone({ app: editBar, body: editBody }));

  DS.frame(g4, '20', 'Confirmation de suppression', 'Écran dédié. « Annuler » est l’action mise en avant.', phone({
    app: { close: true, title: 'Supprimer' },
    body: `<div class="col grow pad center" style="justify-content:center">
        <div class="illus err">${I('delete')}</div>
        <div class="t-hs mt24">Supprimer ce document ?</div>
        <div class="card flush mt16" style="text-align:left">${docTile('releve')}</div>
        <p class="t-bm muted mt16" style="margin-bottom:0">Cette action est <b>définitive</b>. Le document sera effacé de votre coffre et ne pourra pas être récupéré.</p>
      </div>
      <div class="pad col g8" style="padding-bottom:16px">${btn('Annuler', 'tonal lg block')}${btn('Supprimer définitivement', 'danger lg block', 'delete')}</div>`,
  }));

  /* =====================================================================
     5. Ajouter un document
     ===================================================================== */
  const g5 = DS.group('g5', '5. Ajouter un document',
    'Scanner, importer ou recevoir un fichier d’une autre application : les trois chemins mènent au même formulaire, puis au chiffrement.');

  DS.frame(g5, '8', 'Scanner', 'Point d’entrée. « Numériser » ouvre le scanner du système (détection des contours, recadrage, filtres).', phone({
    app: { title: 'Scanner' }, nav: 'scan',
    body: `<div class="col pad center" style="padding-top:4px">
        <div class="illus md">${I('document_scanner')}</div>
        <div class="t-hs mt16">Numériser un document</div>
        <p class="t-bm muted mt8" style="margin-bottom:0">Les contours sont détectés automatiquement. Vous pourrez recadrer et ajouter plusieurs pages.</p>
      </div>
      <div class="pad col g8 mt24">${btn('Numériser', 'filled lg block', 'photo_camera')}${btn('Importer des photos', 'tonal lg block', 'photo_library')}</div>
      <div class="pad mt16"><div class="card" style="padding:12px 16px">
        <div class="t-ts" style="margin-bottom:4px">Pour un bon résultat</div>
        <div class="row g12 muted t-bm" style="padding:4px 0">${I('wb_sunny')}Bonne lumière, sans reflet</div>
        <div class="row g12 muted t-bm" style="padding:4px 0">${I('straighten')}Document bien à plat</div>
        <div class="row g12 muted t-bm" style="padding:4px 0">${I('contrast')}Fond d’une couleur différente</div>
      </div></div>`,
  }));

  DS.frame(g5, '9', 'Prévisualisation du scan', 'Réorganiser par glisser-déposer, retirer une page, en ajouter, ou tout recommencer.', phone({
    app: { close: true, title: 'Aperçu du scan' },
    body: `<div class="pad">
        <p class="t-bm muted" style="margin:0 0 12px">3 pages. Maintenez une page pour la déplacer.</p>
        <div class="grid2">
          ${[1, 2, 3].map((n) => `<div class="page-tile"><span class="num">${n}</span><span class="rm">${I('close')}</span>${thumb(n === 1 ? 'letter' : 'doc', 'lg')}<span class="grip">${I('drag_indicator')}</span></div>`).join('')}
          <div class="page-tile add">${I('add_a_photo')}<span>Ajouter des pages</span></div>
        </div>
      </div>
      <div class="pad row g8 mt-auto" style="padding-top:12px;padding-bottom:16px">${btn('Recommencer', 'outlined flex1', 'restart_alt')}${btn('Continuer', 'filled flex1', 'arrow_forward')}</div>`,
  }));

  const infoBody = `<div class="pad col g24" style="padding-top:8px">
        <div class="row g16">${thumb('letter', 'md')}<div class="col g4"><span class="t-tm">3 pages · PDF</span><span class="secure-line">${I('lock-fill')}Sera chiffré à l’enregistrement</span></div></div>
        ${field('Nom', 'Scan du 13/11/2026', { focus: true })}
        ${field('Catégorie', 'Identité', { trail: 'expand_more' })}
        ${field('Type de document', '', { ph: 'Ex. : passeport, facture' })}
        ${field('Date d’expiration', '', { ph: 'Facultatif', trail: 'calendar_month' })}
        ${field('Tags', '', { ph: 'Facultatif' })}
      </div>
      <div class="pad mt-auto" style="padding-bottom:16px">${btn('Enregistrer dans le coffre', 'filled lg block', 'lock')}</div>`;

  DS.frame(g5, '9b', 'Informations du document', 'Même formulaire après un scan, une importation ou un partage. Seuls le nom et la catégorie sont obligatoires.', phone({
    app: { back: true, title: 'Informations' }, body: infoBody,
  }));

  DS.frame(g5, '9c', 'Enregistrement', 'Création du PDF puis chiffrement, avec progression. Les fichiers temporaires sont supprimés à la fin.', phone({
    app: { back: true, title: 'Informations' }, body: infoBody,
    overlay: `<div class="scrim mid"><div class="dialog"><h3>Enregistrement…</h3>
        <div class="row g12" style="padding:6px 0">${I('check_circle-fill', 'c-tertiary')}<span class="t-bl" style="color:var(--on-surface)">Création du PDF</span></div>
        <div class="row g12" style="padding:6px 0">${I('lock', 'c-primary')}<span class="t-bl" style="color:var(--on-surface)">Chiffrement</span><span style="margin-left:auto">62 %</span></div>
        <div class="linear mt8"><i style="width:62%"></i></div>
        <p style="margin:16px 0 0">Ne fermez pas l’application.</p></div></div>`,
  }));

  const srcIcon = (icon) => `<span class="cat" style="--cat-bg:var(--primary-container);--cat-fg:var(--on-primary-container)">${I(icon)}</span>`;
  DS.frame(g5, '10', 'Importation', 'Chaque fichier est vérifié : type réel, taille, lisibilité, doublon. Un fichier refusé est expliqué.', phone({
    app: { back: true, title: 'Importer' },
    body: `<div class="pad row g12" style="align-items:stretch">
        <div class="src-card">${srcIcon('file_open')}<b>Fichiers</b><span>PDF et images</span></div>
        <div class="src-card">${srcIcon('photo_library')}<b>Galerie</b><span>Photos</span></div>
      </div>
      ${section('4 fichiers sélectionnés')}
      ${tile({ lead: thumb('letter'), title: 'Contrat de bail.pdf', sub: 'PDF · 2,4 Mo', trail: I('check_circle-fill', 'c-success') })}
      ${tile({ lead: thumb('photo'), title: 'IMG_2041.jpg', sub: 'JPEG · 3,1 Mo', trail: I('check_circle-fill', 'c-success') })}
      ${tile({ lead: thumb('invoice'), title: 'Facture octobre.pdf', sub: '<span class="c-warning">Déjà dans votre coffre</span>', trail: I('warning-fill', 'c-warning') })}
      ${tile({ lead: `<span class="thumb" style="display:grid;place-items:center;background:var(--surface-container-high)">${I('draft', 'muted')}</span>`, title: 'notes.docx', sub: '<span class="c-error">Format non pris en charge</span>', trail: I('error-fill', 'c-error') })}
      <div class="pad col g12 mt-auto" style="padding-bottom:16px">
        <p class="t-bs muted center" style="margin:0">Formats acceptés : PDF, JPEG et PNG.</p>
        ${btn('Continuer avec 2 fichiers', 'filled lg block')}
      </div>`,
  }));
})();
