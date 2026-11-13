/* DocuSafe – maquettes, écrans 11 à 21 : recherche, catégories, échéances, partage, paramètres, erreurs. */
(function () {
  'use strict';
  const { I, logo, phone, btn, chip, badge, sw, cat, lead, chev, section, field, tile, thumb, docTile, CATS } = window.UI;
  const DS = window.DS;
  const P = DS.parts;

  /* =====================================================================
     6. Recherche et catégories
     ===================================================================== */
  const g6 = DS.group('g6', '6. Recherche et catégories',
    'La recherche fonctionne hors ligne, dès les premières lettres, sans tenir compte des majuscules ni des accents.');

  const searchTop = (query, filters) =>
    `<div class="pad" style="padding-top:8px"><div class="searchbar">${I('arrow_back')}<span class="q">${query}<span class="caret"></span></span>${I('close')}</div></div>
      <div class="chips pad" style="padding-top:12px">${filters}</div>`;
  const filters = chip('Identité', { on: true }) + chip('Tags', { trail: 'expand_more' }) + chip('Format', { trail: 'expand_more' }) + chip('Date', { trail: 'expand_more' });

  DS.frame(g6, '12a', 'Recherche', 'Résultats pendant la saisie. Le texte trouvé est mis en évidence. Filtres combinables.', phone({
    body: `${searchTop('pass', filters)}
      <div class="pad t-lm muted" style="padding-top:16px;padding-bottom:4px">3 résultats</div>
      ${docTile('passeport', { title: '<mark>Pass</mark>eport' })}
      ${tile({ lead: thumb('doc'), title: 'Reçu de demande de <mark>pass</mark>eport', sub: 'Identité · PDF · 1 page' })}
      ${docTile('visa', { sub: 'Tag : <mark>pass</mark>eport · Identité · JPEG' })}`,
  }));

  DS.frame(g6, '12b', 'Aucun résultat', 'État vide avec un conseil et une action.', phone({
    body: `${searchTop('bulletin 2019', filters)}
      <div class="empty"><div class="illus big">${I('search_off')}</div><h3>Aucun résultat</h3>
        <p>Essayez un autre mot ou retirez un filtre.</p>
        <div class="mt24">${btn('Effacer les filtres', 'tonal')}</div></div>`,
  }));

  const catList = Object.keys(CATS)
    .map((k) => tile({ lead: cat(k), title: CATS[k].n, sub: `${CATS[k].count} documents${k === 'autres' ? ' · par défaut' : ''}`, trail: I('drag_indicator') }))
    .join('');
  const catBar = { back: true, title: 'Catégories' };
  const catFab = `<span class="fab">${I('add')}Nouvelle catégorie</span>`;

  DS.frame(g6, '11a', 'Catégories', 'Toucher une catégorie pour la modifier. La poignée sert à changer l’ordre.', phone({
    app: catBar, body: catList, fab: catFab,
  }));

  const iconChoices = ['medical_services', 'favorite', 'badge', 'school', 'work', 'account_balance_wallet', 'home_work', 'receipt_long', 'flight', 'directions_car', 'folder', 'sell'];
  const colorChoices = ['blue', 'indigo', 'purple', 'pink', 'red', 'orange', 'amber', 'green', 'teal', 'cyan', 'brown', 'slate'];
  DS.frame(g6, '11b', 'Créer ou modifier une catégorie', 'Nom, icône et couleur, avec aperçu immédiat. Douze couleurs lisibles en clair comme en sombre.', phone({
    app: { close: true, title: 'Modifier', actions: ['<span class="btn text">Enregistrer</span>'] },
    body: `<div class="col pad" style="align-items:center;padding-top:4px">${cat('sante', 'lg')}<div class="t-tm mt8">Santé</div><span class="t-bs muted">11 documents</span></div>
      <div class="pad mt24">${field('Nom', 'Santé', { focus: true })}</div>
      <div class="grp">Icône</div>
      <div class="pad"><div class="grid6 c-pink">${iconChoices.map((ic, k) => `<span class="icon-opt${k === 0 ? ' on' : ''}">${I(ic)}</span>`).join('')}</div></div>
      <div class="grp">Couleur</div>
      <div class="pad"><div class="swatches">${colorChoices.map((c) => `<span class="swatch c-${c}${c === 'pink' ? ' on' : ''}">${c === 'pink' ? I('check') : '<i class="dot"></i>'}</span>`).join('')}</div></div>
      <div class="pad mt-auto" style="padding-bottom:12px">${btn('Supprimer la catégorie', 'text danger block', 'delete')}</div>`,
  }));

  DS.frame(g6, '11c', 'Supprimer une catégorie', 'Les documents ne sont jamais supprimés avec la catégorie : l’utilisateur choisit où les déplacer.', phone({
    app: catBar, body: catList, fab: catFab,
    overlay: `<div class="scrim mid"><div class="dialog">
        <h3>Supprimer «&nbsp;Immobilier&nbsp;»&nbsp;?</h3>
        <p style="margin:0 0 20px">Ses 9 documents ne seront pas supprimés. Choisissez où les déplacer.</p>
        ${field('Déplacer vers', 'Autres', { trail: 'expand_more' })}
        <div class="actions">${btn('Annuler', 'text')}${btn('Déplacer et supprimer', 'text danger')}</div>
      </div></div>`,
  }));

  /* =====================================================================
     7. Échéances
     ===================================================================== */
  const g7 = DS.group('g7', '7. Échéances et rappels',
    'Trois couleurs d’état seulement : rouge pour « expiré », ambre pour « bientôt », neutre pour le reste.');

  DS.frame(g7, '15', 'Échéances', 'Classées par urgence. Cet onglet reste la référence même si une notification est manquée.', phone({
    app: { title: 'Échéances', actions: ['tune'] }, nav: 'dead', bodyCls: 'fade',
    body: `<div class="chips pad" style="padding-bottom:4px">${chip('Toutes', { on: true })}${chip('Expirés · 1')}${chip('30 jours · 2')}</div>
      <div class="grp neutral">Expirés</div>
      ${docTile('permis', { sub: 'Expiré le 2 nov. 2026', trail: badge('Depuis 11 j', 'err') })}
      <div class="grp neutral">Dans les 30 jours</div>
      ${docTile('visa', { sub: 'Expire le 20 nov. 2026', trail: badge('J-7', 'warn') })}
      ${docTile('assurance', { sub: 'Expire le 1er déc. 2026', trail: badge('J-18', 'warn') })}
      <div class="grp neutral">Plus tard</div>
      ${docTile('passeport', { sub: 'Expire le 14 févr. 2027', trail: badge('3 mois') })}
      ${docTile('bail', { sub: 'Expire le 31 août 2027', trail: badge('9 mois') })}
      ${docTile('electeur', { sub: 'Expire le 9 juin 2028', trail: badge('1 an 6 mois') })}`,
  }));

  DS.frame(g7, '16', 'Rappels d’un document', 'Quatre rappels par défaut, chacun désactivable. Les rappels déjà passés sont grisés.', phone({
    app: { back: true, title: 'Rappels' },
    body: `<div class="pad"><div class="card flush">${docTile('visa', { sub: 'Expire le 20 nov. 2026', trail: badge('J-7', 'warn') })}</div></div>
      <div class="pad mt16">${field('Date d’expiration', '20/11/2026', { trail: 'calendar_month' })}</div>
      <div class="grp">Rappels</div>
      ${tile({ title: '90 jours avant', sub: '22 août 2026 · passé', trail: sw(false), cls: 'off' })}
      ${tile({ title: '30 jours avant', sub: '21 oct. 2026 · passé', trail: sw(false), cls: 'off' })}
      ${tile({ title: '7 jours avant', sub: 'Aujourd’hui, vers 09:00', trail: sw(true) })}
      ${tile({ title: 'Le jour même', sub: '20 nov. 2026, vers 09:00', trail: sw(true) })}
      <div class="pad">${btn('Ajouter un rappel', 'text', 'add')}</div>
      <div class="pad mt-auto" style="padding-bottom:16px"><div class="banner info">${I('info')}<span>Par discrétion, la notification n’affiche pas le nom du document.</span></div></div>`,
  }));

  DS.frame(g7, '16b', 'Demande d’autorisation', 'Affichée à la première date d’expiration, avant la demande du système. Jamais au lancement.', phone({
    app: P.editBar, body: P.editBody,
    overlay: `<div class="scrim low"><div class="sheet"><div class="handle"></div>
        <div class="illus sm">${I('notifications_active')}</div>
        <h3 class="center mt16">Être prévenu avant l’expiration&nbsp;?</h3>
        <p class="t-bm center" style="margin:0 0 20px">DocuSafe vous rappelle l’échéance 90, 30 et 7 jours avant, puis le jour même. Les rappels restent sur votre téléphone.</p>
        <div class="col g8">${btn('Autoriser les notifications', 'filled lg block')}${btn('Plus tard', 'text block')}</div>
      </div></div>`,
  }));

  /* =====================================================================
     8. Partage et export
     ===================================================================== */
  const g8 = DS.group('g8', '8. Partage et export',
    'Deux étapes obligatoires avant qu’un document ne sorte du coffre : prouver son identité, puis lire l’avertissement.');

  DS.frame(g8, '10a', 'Nouvelle authentification', 'Biométrie si elle est activée, sinon le clavier du code. Non redemandée si l’on vient de se déverrouiller.', phone({
    app: P.detailBar, body: P.detailBody,
    overlay: `<div class="scrim low"><div class="sheet"><div class="handle"></div>
        <div class="row g8" style="justify-content:center">${logo(20)}<span class="t-lm">DocuSafe</span></div>
        <h3 class="center mt12">Confirmez votre identité</h3>
        <p class="t-bm center" style="margin:0">Pour partager «&nbsp;Passeport&nbsp;»</p>
        <div class="illus sm sec mt24">${I('fingerprint')}</div>
        <p class="t-bm center mt12" style="margin-bottom:16px">Touchez le capteur d’empreinte</p>
        <div class="row" style="justify-content:center">${btn('Utiliser mon code', 'text')}</div>
        <p class="sysnote mt8" style="margin-bottom:4px">Fenêtre du système : son apparence dépend du téléphone.</p>
      </div></div>`,
  }));

  DS.frame(g8, '10b', 'Avertissement avant partage', 'Rappelle que le fichier partagé n’est plus protégé. Même principe pour l’export.', phone({
    app: P.detailBar, body: P.detailBody,
    overlay: `<div class="scrim mid"><div class="dialog centered">
        <div class="d-ic">${I('share')}</div>
        <h3>Partager ce document&nbsp;?</h3>
        <p style="margin:0">Le fichier partagé <b>ne sera plus protégé</b> par DocuSafe. Envoyez-le uniquement à une personne de confiance.</p>
        <div class="actions">${btn('Annuler', 'text')}${btn('Continuer', 'text')}</div>
      </div></div>`,
  }));

  /* =====================================================================
     9. Paramètres
     ===================================================================== */
  const g9 = DS.group('g9', '9. Paramètres',
    'Toutes les sections demandées par le cahier des charges. Aucune option factice : ce qui n’existe pas encore est indiqué comme indisponible.');

  const value = (text) => `<span class="t-bm">${text}</span>${chev()}`;
  DS.frame(g9, '18', 'Paramètres', 'Dix entrées, regroupées par thème : protection, données, informations.', phone({
    app: { title: 'Paramètres' }, nav: 'set',
    bodyCls: 'compact',
    body: `${tile({ lead: `<span class="cat" style="border-radius:50%;--cat-bg:var(--primary-container);--cat-fg:var(--on-primary-container)">${I('person')}</span>`, title: 'Profil local', sub: 'Nom affiché sur l’accueil', trail: chev() })}
      <div class="divider"></div>
      ${tile({ lead: lead('shield_lock'), title: 'Sécurité', trail: chev() })}
      ${tile({ lead: lead('notifications'), title: 'Notifications', trail: chev() })}
      <div class="divider"></div>
      ${tile({ lead: lead('database'), title: 'Stockage', trail: value('312 Mo') })}
      ${tile({ lead: lead('file_export'), title: 'Exporter mes données', trail: chev() })}
      ${tile({ lead: lead('settings_backup_restore'), title: 'Sauvegarde et synchronisation', trail: chev() })}
      <div class="divider"></div>
      ${tile({ lead: lead('policy'), title: 'Confidentialité', trail: chev() })}
      ${tile({ lead: lead('gavel'), title: 'Conditions d’utilisation', trail: chev() })}
      ${tile({ lead: lead('info'), title: 'À propos', trail: value('1.0.0') })}
      ${tile({ lead: lead('help'), title: 'Assistance', trail: chev() })}`,
  }));

  DS.frame(g9, '17', 'Sécurité', 'Chaque changement demande une nouvelle authentification. La zone sensible est isolée en bas.', phone({
    app: { back: true, title: 'Sécurité' },
    body: `<div class="grp">Accès</div>
      ${tile({ lead: lead('password'), title: 'Changer le code', trail: chev() })}
      ${tile({ lead: lead('fingerprint'), title: 'Empreinte digitale', sub: 'Déverrouiller avec votre empreinte', trail: sw(true) })}
      ${tile({ lead: lead('key'), title: 'Clé de récupération', sub: 'Créer une nouvelle clé', trail: chev() })}
      <div class="grp">Verrouillage</div>
      ${tile({ lead: lead('lock_clock'), title: 'Verrouillage automatique', sub: 'Après 2 minutes sans action', trail: chev() })}
      ${tile({ lead: lead('screenshot_monitor'), title: 'Bloquer les captures d’écran', sub: 'Masque aussi l’aperçu des applications récentes', wrap: true, trail: sw(true) })}
      ${tile({ lead: lead('lock'), title: 'Verrouiller maintenant' })}
      <div class="grp" style="color:var(--error)">Zone sensible</div>
      ${tile({ lead: lead('delete_forever'), title: 'Effacer le coffre', sub: 'Supprime définitivement tous les documents', wrap: true, cls: 'danger' })}`,
  }));

  DS.frame(g9, '17b', 'Notifications', 'L’aperçu montre exactement ce qui s’affichera sur l’écran verrouillé.', phone({
    app: { back: true, title: 'Notifications' },
    body: `${tile({ title: 'Rappels d’échéance', sub: 'Notifications locales, sans Internet', trail: sw(true) })}
      <div class="grp">Rappels par défaut</div>
      <div class="chips wrap pad">${chip('90 jours', { on: true })}${chip('30 jours', { on: true })}${chip('7 jours', { on: true })}${chip('Le jour même', { on: true })}${chip('Ajouter', { icon: 'add' })}</div>
      <div style="height:12px"></div>
      ${tile({ lead: lead('schedule'), title: 'Heure d’envoi', trail: value('09:00') })}
      ${tile({ lead: lead('visibility_off'), title: 'Afficher le nom du document', sub: 'Désactivé : le nom n’apparaît pas sur l’écran verrouillé', wrap: true, trail: sw(false) })}
      <div class="grp">Aperçu</div>
      <div class="pad"><div class="notif">${logo(24)}<div class="col" style="gap:2px"><span class="app">DocuSafe · maintenant</span><span class="t-ts" style="color:var(--on-surface)">Échéance dans 7 jours</span><span class="t-bm muted">Un document de votre coffre arrive à échéance.</span></div></div></div>`,
  }));

  const usage = [['finances', '97 Mo', 31], ['pro', '75 Mo', 24], ['education', '53 Mo', 17], ['identite', '37 Mo', 12], ['immo', '25 Mo', 8], ['sante', '19 Mo', 6], ['autres', '6 Mo', 2]];
  DS.frame(g9, '19', 'Stockage', 'Espace occupé par catégorie et nettoyage des fichiers temporaires.', phone({
    app: { back: true, title: 'Stockage' },
    body: `<div class="pad"><div class="t-hm">312 Mo</div><div class="t-bm muted">128 documents chiffrés · 4,2 Go libres sur le téléphone</div>
        <div class="stack mt16">${usage.map(([k, , w]) => `<i class="c-${CATS[k].c}" style="width:${w}%"></i>`).join('')}</div></div>
      <div style="height:12px"></div>
      ${usage.map(([k, size]) => `<div class="tile dense" style="min-height:44px;padding-top:4px;padding-bottom:4px"><span class="dot c-${CATS[k].c}"></span><div class="tx"><div class="t1" style="font-size:15px">${CATS[k].n}</div></div><div class="trail"><span class="t-bm">${size}</span></div></div>`).join('')}
      <div class="divider" style="margin-top:8px;margin-bottom:8px"></div>
      ${tile({ lead: lead('cleaning_services'), title: 'Fichiers temporaires', sub: 'Aucun fichier en attente', trail: btn('Nettoyer', 'tonal') })}`,
  }));

  DS.frame(g9, '19b', 'Sauvegarde et synchronisation', 'Sauvegarde chiffrée manuelle (choix D13). La synchronisation est annoncée comme indisponible, sans bouton.', phone({
    app: { back: true, title: 'Sauvegarde' },
    body: `<div class="pad col g16">
        <div class="banner sec">${I('smartphone')}<span>Vos documents se trouvent <b>uniquement sur ce téléphone</b>. Une sauvegarde vous protège en cas de perte ou de panne.</span></div>
        <div class="card col g12">
          <div class="row g12">${I('settings_backup_restore', 'c-primary')}<div><div class="t-tm">Sauvegarde chiffrée</div><div class="t-bm muted">Dernière : 2 nov. 2026 · 298 Mo</div></div></div>
          ${btn('Créer une sauvegarde', 'filled block', 'save')}
          ${btn('Restaurer une sauvegarde', 'outlined block', 'restore')}
        </div>
        <p class="t-bm muted" style="margin:0">Le fichier est chiffré. Pour le restaurer, il faut votre <b>clé de récupération</b>. Conservez-le hors du téléphone : carte mémoire, ordinateur, clé USB.</p>
      </div>
      <div class="grp">Synchronisation</div>
      ${tile({ lead: lead('cloud_off'), title: 'Non disponible', sub: 'Prévue dans une version future', cls: 'off' })}`,
  }));

  /* =====================================================================
     10. Erreurs et états vides
     ===================================================================== */
  const g10 = DS.group('g10', '10. Erreurs et états vides',
    'Toujours la même structure : une image simple, ce qui se passe, ce que l’utilisateur peut faire. Jamais de message technique.');

  const state = (o) =>
    `<div class="empty"><div class="illus big ${o.kind || ''}">${I(o.icon)}</div><h3>${o.title}</h3><p>${o.text}</p>
      <div class="col g8 mt24" style="width:100%">${o.actions}</div></div>`;

  DS.frame(g10, '21a', 'Liste vide', 'Chaque liste explique quoi faire quand elle est vide.', phone({
    app: { title: 'Documents', actions: ['search', 'swap_vert'] }, nav: 'docs',
    fab: `<span class="fab">${I('add')}</span>`,
    body: `<div class="tabs"><a class="on">Tous</a><a>Favoris</a><a>Récents</a></div>
      <div class="chips pad" style="padding-top:12px;padding-bottom:4px">${chip('Toutes')}${chip('Identité')}${chip('Santé', { on: true })}${chip('Finances')}</div>
      ${state({ icon: 'folder_open', title: 'Aucun document dans Santé', text: 'Scannez ou importez un document, puis classez-le dans cette catégorie.', actions: '' })}`,
  }));

  DS.frame(g10, '21b', 'Document illisible', 'Fichier modifié ou endommagé : le contenu n’est jamais affiché.', phone({
    app: { back: true, title: 'Relevé de notes – L3' },
    body: state({ kind: 'err', icon: 'broken_image', title: 'Document illisible',
      text: 'Ce fichier a été modifié ou endommagé. Par sécurité, DocuSafe ne l’affiche pas.',
      actions: btn('Retour', 'tonal lg block') + btn('Supprimer la fiche', 'text danger block') }),
  }));

  DS.frame(g10, '21c', 'Espace insuffisant', 'L’opération est annulée proprement : rien n’est perdu.', phone({
    app: { back: true, title: 'Informations' },
    body: state({ kind: 'warn', icon: 'sd_card', title: 'Espace insuffisant',
      text: 'Il manque 12 Mo sur le téléphone pour enregistrer ce document. Votre scan est conservé pour l’instant.',
      actions: btn('Gérer le stockage', 'filled lg block') + btn('Annuler', 'text block') }),
  }));

  DS.frame(g10, '21d', 'Permission refusée', 'Explication et lien direct vers les réglages, avec une solution de rechange.', phone({
    app: { title: 'Scanner' }, nav: 'scan',
    body: state({ icon: 'no_photography', title: 'Appareil photo non autorisé',
      text: 'Pour numériser, autorisez l’appareil photo dans les réglages du téléphone.',
      actions: btn('Ouvrir les réglages', 'filled lg block', 'open_in_new') + btn('Importer un fichier à la place', 'text block') }),
  }));

  DS.frame(g10, '21e', 'Erreur imprévue', 'Écran générique. Les détails techniques ne sont jamais montrés.', phone({
    app: { back: true },
    body: state({ icon: 'report', title: 'Une erreur est survenue',
      text: 'Vos documents ne sont pas touchés. Vous pouvez réessayer.',
      actions: btn('Réessayer', 'filled lg block', 'restart_alt') }),
  }));
})();
