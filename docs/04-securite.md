# Sécurité de DocSafe

Document rédigé le 13/11/2026 (phase 1). Il définit les règles de sécurité à respecter pendant tout le développement. Il sera complété en phase 5 par les résultats des tests.

---

## 1. Principes

1. **Rien n'est stocké en clair.** Documents, miniatures, titres, tags, index de recherche : tout est chiffré sur le téléphone.
2. **Sans authentification, pas de clé.** Quand le coffre est verrouillé, la clé n'existe plus en mémoire. La protection ne repose pas sur un simple écran qui cache le contenu.
3. **La biométrie ne chiffre rien.** Elle autorise le téléphone à libérer une clé protégée par son matériel.
4. **Rien ne sort sans un geste volontaire.** Pas de serveur, pas de permission Internet, pas de sauvegarde automatique.
5. **Pas de porte dérobée.** Personne, pas même l'éditeur de DocSafe, ne peut ouvrir un coffre sans le PIN, la biométrie ou la clé de récupération.
6. **Les limites sont écrites noir sur blanc** (§19).

---

## 2. Données sensibles

| Donnée | Sensibilité | Protection |
|---|---|---|
| Contenu des documents | Très élevée | Fichiers chiffrés (AES-256-GCM) |
| Miniatures | Très élevée | Chiffrées comme les documents |
| Texte extrait par OCR | Très élevée | Dans la base chiffrée |
| Titres, descriptions, tags, dates, catégories | Élevée (« Passeport de… ») | Base entièrement chiffrée |
| Clé du coffre, PIN, clé de récupération | Critique | Voir §4 à §7 |
| Fichiers temporaires (scan, import, partage) | Très élevée, courte durée | Dossier privé, purge systématique (§12) |
| Texte des notifications | Moyenne | Générique par défaut (§14) |
| Ce qui est affiché à l'écran | Élevée | Captures bloquées, aperçu masqué (§15) |
| Journaux techniques | — | Ne contiennent aucune de ces données (§15) |

---

## 3. Analyse des risques

| Situation | Protection | Risque restant |
|---|---|---|
| Téléphone perdu ou volé, DocSafe verrouillé | Tout est chiffré. La clé n'est pas en mémoire. Elle est enfermée dans le stockage sécurisé du téléphone **et** protégée par le PIN. | Très faible |
| Téléphone pris alors que DocSafe est ouvert | Verrouillage immédiat en arrière-plan, verrouillage après inactivité, nouvelle authentification avant un partage ou un export | Ce qui est à l'écran reste visible jusqu'au verrouillage |
| Autre application installée sur le téléphone | Dossier privé de l'application, aucun fichier en clair ailleurs, captures d'écran bloquées | Très faible |
| Téléphone « rooté » ou infecté par un logiciel ayant tous les droits | Données chiffrées au repos, clé biométrique liée au matériel, PIN nécessaire | **Si le coffre est déverrouillé pendant l'attaque, la clé est en mémoire.** Aucune application ne peut se protéger d'un téléphone entièrement compromis. |
| Sauvegarde cloud du téléphone (Google, iCloud) | Sauvegarde automatique désactivée pour DocSafe | L'utilisateur doit faire ses propres sauvegardes |
| Regard indiscret, aperçu des applications récentes | Captures bloquées, aperçu masqué, PIN masqué à la saisie | Sur iOS, les captures d'écran ne peuvent pas être bloquées |
| Essais répétés du PIN | Calcul volontairement lent, délais croissants après 5 échecs | Voir limite n°2 (§19) |
| Biométrie ajoutée par un tiers | La clé biométrique est détruite dès qu'une empreinte ou un visage est ajouté au téléphone | Contrainte physique sur l'utilisateur : hors de portée d'une application |
| Fichier chiffré modifié, tronqué ou remplacé | Chiffrement authentifié bloc par bloc + empreinte SHA-256 en base | Aucun : le document est signalé comme corrompu, jamais affiché |
| Coupure pendant un enregistrement | Écriture sous un nom provisoire, renommage en une opération, contrôle de cohérence | Aucun |
| Fichier importé piégé | Vérification du type réel et de la taille ; lecteur PDF tenu à jour | Une faille inconnue du lecteur PDF reste possible |
| Fuite par les journaux, les notifications, le presse-papiers | Journal sans données, notifications génériques, presse-papiers marqué sensible et vidé | Très faible |
| Paquet tiers compromis | Éditeurs vérifiés, versions figées, binaires SQLite contrôlés par empreinte | Risque propre à tout logiciel |
| PIN **et** clé de récupération perdus | Explication claire à la création du coffre | **Perte définitive des documents** |

---

## 4. Les clés

### 4.1. Organisation

```
   PIN ────────────────── calcul lent (Argon2id) ───────────┐
   Clé de récupération ── dérivation ───────────────────────┼──►  CLÉ DU COFFRE
   Biométrie ──────────── clé matérielle du téléphone ──────┘     256 bits, aléatoire
                                                                         │
                         ┌───────────────────────┬───────────────────────┤
                         ▼                       ▼                       ▼
                 clé de la base         une clé par fichier      une clé par miniature
```

- La **clé du coffre** est tirée au hasard à la création du coffre. Elle n'est jamais écrite en clair sur le stockage. Elle n'existe en mémoire que lorsque le coffre est déverrouillé.
- Elle est enfermée dans **trois serrures indépendantes** : PIN, clé de récupération, biométrie (facultative). Chaque serrure contient la clé du coffre chiffrée en AES-256-GCM avec une clé différente.
- Les clés de travail (base, fichiers, miniatures) sont **dérivées** de la clé du coffre (HKDF-SHA256, avec une étiquette différente pour chaque usage). Aucune clé ne sert à deux choses.
- Conséquence pratique : **changer de PIN ne rechiffre aucun document**. Seule la serrure du PIN est refaite. L'opération est instantanée.

### 4.2. Emplacement

| Élément | Où | Ce qu'il faut pour l'utiliser |
|---|---|---|
| Serrure du PIN | Stockage sécurisé du système (Android Keystore, Trousseau iOS) | Ce téléphone **et** le PIN |
| Serrure biométrique | Stockage sécurisé, zone exigeant une authentification biométrique | Ce téléphone **et** une biométrie reconnue |
| Serrure de récupération | Fichier `vault/recovery.slot` | La clé de récupération (qui n'est stockée nulle part) |
| Compteur de tentatives, indicateurs de configuration | Stockage sécurisé du système | — |
| Clé du coffre et clés dérivées | Mémoire vive uniquement | Effacées au verrouillage |

Le stockage sécurisé est fourni par `flutter_secure_storage`. Sur Android, les valeurs sont chiffrées par une clé que le Keystore ne laisse pas sortir du téléphone.

---

## 5. Code PIN

| Règle | Valeur |
|---|---|
| Longueur | 6 à 12 chiffres |
| Codes refusés | Suites et répétitions évidentes (`000000`, `123456`, `111111`…) |
| Saisie | Clavier numérique dessiné par l'application (pas le clavier du système), chiffres masqués |
| Stockage | **Le PIN n'est jamais stocké**, ni son empreinte |
| Vérification | On tente d'ouvrir la serrure avec la clé calculée à partir du PIN. Si le PIN est faux, l'ouverture échoue. |
| Calcul | **Argon2id**, dans un isolate. Départ : 19 Mo de mémoire, 2 passes. Réglage final en phase 3 sur un vrai téléphone d'entrée de gamme (objectif : 0,5 à 1 seconde). |
| Évolution | Les paramètres sont enregistrés avec la serrure : ils pourront être durcis plus tard sans rien casser |
| Essais | 5 essais libres, puis attente : 30 s, 1 min, 5 min, 15 min, 1 h. Le compteur survit à la fermeture de l'application. |
| Effacement automatique après N échecs | Non, dans le MVP (risque de perte par accident ou par malveillance) |

Plan B si Argon2id est trop lent sur les téléphones modestes : PBKDF2-HMAC-SHA256 exécuté en natif. Le format de la serrure prévoit déjà ce changement.

---

## 6. Biométrie

- **Android 9 et plus :** une copie de la clé du coffre est placée dans une zone du Keystore dont la clé n'est utilisable **qu'après une authentification biométrique forte**. C'est le matériel du téléphone qui fait respecter cette règle, pas l'application.
- **Android 7 et 8 :** le paquet de stockage sécurisé n'assure pas cette protection matérielle sur ces versions. Plutôt que d'offrir une biométrie plus faible, DocSafe ne la propose pas : le PIN seul est utilisé.
- **iOS** (à vérifier sur iOS) : trousseau avec contrôle d'accès biométrique, protégé par la Secure Enclave.
- **Reconnaissance faciale sur Android :** proposée uniquement si le téléphone la classe comme « forte ». Sur beaucoup de modèles, seule l'empreinte digitale l'est.
- **Nouvelle empreinte ou nouveau visage ajouté au téléphone :** la clé biométrique est détruite par le système. DocSafe redemande le PIN et propose de réactiver la biométrie.
- **Le PIN reste toujours valable.** Activer ou désactiver la biométrie exige le PIN.

Le paquet `local_auth` sert à savoir si une biométrie est disponible, et à confirmer une opération sensible quand le coffre est déjà ouvert (§11).

---

## 7. Clé de récupération

| Règle | Valeur |
|---|---|
| Forme | 32 caractères en 8 groupes de 4 (`XXXX-XXXX-…`), sans caractères ambigus (pas de I, L, O, U) |
| Solidité | 160 bits aléatoires : impossible à deviner |
| Création | Automatique, à la création du coffre, en silence (D6 révisée le 14/11/2026) |
| Affichage | **Une seule fois**, quand l'utilisateur touche « Noter ma clé » (rappel sur l'accueil et dans les réglages jusqu'à sa confirmation). Comme la clé n'est jamais stockée, « Noter ma clé » en génère une nouvelle au moment de l'afficher. L'utilisateur confirme l'avoir conservée. |
| Copie | Bouton « Copier » : le presse-papiers est marqué sensible et vidé après 60 secondes |
| Stockage sur le téléphone | **Aucun** |
| Utilisation | « Code oublié ? » → saisie de la clé → choix d'un nouveau PIN |
| Autre utilité | Rouvrir le coffre si le stockage sécurisé du téléphone est endommagé |
| Renouvellement | Possible dans les paramètres après authentification. L'ancienne clé cesse de fonctionner. |

**Message affiché à l'utilisateur (exigence du §3.1) :** sans le PIN et sans la clé de récupération, les documents sont définitivement inaccessibles. Personne ne peut les récupérer.

Oublier le PIN alors que la biométrie fonctionne encore ne suffit pas pour en choisir un nouveau : il faut l'ancien PIN ou la clé de récupération.

---

## 8. Chiffrement des fichiers

Algorithme : **AES-256-GCM**. Il chiffre et détecte toute modification.

### Format d'un fichier chiffré (`.dsf`, version 1)

| Partie | Taille | Contenu |
|---|---|---|
| Signature | 4 octets | `DSF1` |
| Version, algorithme, options | 4 octets | Permet de faire évoluer le format |
| Taille des blocs | 4 octets | 1 Mo par défaut |
| Sel | 16 octets | Aléatoire, unique par fichier |
| Réservé | 4 octets | — |
| Blocs chiffrés | variable | Chaque bloc : données chiffrées + sceau d'authenticité de 16 octets |

Règles :

- **Une clé par fichier**, dérivée de la clé du coffre et du sel du fichier.
- **Chaque bloc est scellé avec sa position et l'en-tête du fichier.** Déplacer, retirer ou échanger des blocs est détecté.
- **Le dernier bloc est marqué comme dernier.** Un fichier tronqué est détecté.
- **Empreinte SHA-256** du fichier d'origine calculée pendant le chiffrement et enregistrée dans la base. Elle est vérifiée à chaque lecture complète : cela détecte aussi le remplacement d'un fichier chiffré par un autre.
- **Traitement par blocs** : un document de 100 Mo n'occupe jamais plus de quelques Mo de mémoire.

### Écriture sûre

1. Écriture dans `<nom>.dsf.part`.
2. Vidage des tampons sur le stockage.
3. Relecture de contrôle (déchiffrement et comparaison de l'empreinte).
4. Renommage en `<nom>.dsf` (opération unique).
5. Enregistrement en base.
6. Suppression du fichier d'origine en clair.

À chaque déverrouillage, un contrôle supprime les fichiers `.part` et les fichiers chiffrés sans ligne en base, et signale les lignes dont le fichier a disparu.

Les miniatures utilisent le même format, avec leur propre clé.

---

## 9. Chiffrement de la base

- Moteur : **SQLite3MultipleCiphers**, fourni par le paquet `sqlite3`. La base est chiffrée page par page, journal compris.
- Clé : dérivée de la clé du coffre. La base est donc illisible tant que le coffre est verrouillé.
- Sont ainsi protégés : titres, descriptions, tags, dates, catégories, réglages, index de recherche, texte OCR.
- Les données effacées sont écrasées dans le fichier de la base (`secure_delete`).

**Confirmé en phase 3 :** schéma **ChaCha20-Poly1305** (celui par défaut de SQLite3MultipleCiphers 2.6.1), clé brute de 32 octets passée par `PRAGMA key = "x'…'"` (pas de dérivation supplémentaire côté SQLite : la clé est déjà dérivée par HKDF). Avant d'appliquer la clé, l'application vérifie que le moteur chiffré est bien présent (`PRAGMA cipher`) et refuse d'ouvrir une base en clair. Les tests vérifient que le fichier ne commence pas par `SQLite format 3` et qu'un SQLite ordinaire ne peut pas le lire.

---

## 10. Verrouillage

| Déclencheur | Délai |
|---|---|
| L'application passe en arrière-plan ou l'écran s'éteint | Immédiat |
| Aucune action à l'écran | 2 minutes par défaut (réglable : 30 s, 1, 2, 5, 10 min) |
| Bouton « Verrouiller » | Immédiat |

**Au verrouillage :** fermeture de la base, effacement des clés en mémoire, libération des documents et miniatures déchiffrés, purge des fichiers temporaires, retour à l'écran de déverrouillage.

**Tolérance pendant une opération lancée par DocSafe.** Le scanner, le sélecteur de fichiers, la feuille de partage et la fenêtre biométrique font techniquement passer l'application en arrière-plan. Verrouiller à cet instant ferait perdre le travail en cours. Règle : tolérance de **5 minutes au maximum**. Au-delà, le coffre se verrouille ; au retour, l'utilisateur se réauthentifie puis reprend là où il en était.

Le même mécanisme sert au partage entrant : si un fichier est partagé vers DocSafe alors que le coffre est verrouillé, il attend dans le dossier temporaire privé jusqu'au déverrouillage.

---

## 11. Nouvelle authentification avant une opération sensible

Biométrie si elle est activée, sinon PIN, avant de :

- partager ou exporter un document ;
- exporter l'ensemble des données ;
- changer le PIN, activer ou désactiver la biométrie ;
- renouveler la clé de récupération ;
- autoriser les captures d'écran ;
- effacer le coffre.

Si l'utilisateur vient de s'authentifier (moins de 30 secondes), la demande n'est pas répétée.

La suppression d'un document demande une **confirmation explicite** (écran dédié avec le nom du document), mais pas de nouvelle authentification : elle ne révèle aucune donnée.

---

## 12. Fichiers temporaires

Un fichier en clair existe forcément un court instant : à la sortie du scanner, après le choix d'un fichier, pendant un partage.

| Règle | Détail |
|---|---|
| Un seul emplacement | `secure_tmp/`, dans le cache **privé** de l'application |
| Noms | Aléatoires, sans rapport avec le document |
| Purge | À la fin de chaque opération, au verrouillage, au démarrage |
| Fichiers créés par les paquets | Nettoyage explicite des caches du scanner et des sélecteurs après chaque utilisation |
| Lecture d'un document | Déchiffré **en mémoire** jusqu'à 20 Mo. Au-delà, fichier temporaire supprimé à la fermeture du lecteur. |
| Sauvegardes | Dossiers temporaires exclus de toute sauvegarde |

Point d'attention : sur Android, le scanner écrit ses images dans le dossier « externe privé » de l'application. Sur Android 10 et versions antérieures, ce dossier est moins bien isolé que le dossier interne. DocSafe chiffre donc les pages puis vide ce dossier aussitôt le scan terminé.

---

## 13. Partage et export

1. Nouvelle authentification.
2. Avertissement : « Le fichier partagé ne sera plus protégé par DocSafe. »
3. Déchiffrement et contrôle d'intégrité.
4. **Partage** : fichier temporaire dans `secure_tmp/`, transmis par la feuille de partage du système avec un droit de lecture temporaire. **Export** : écriture directe à l'emplacement choisi par l'utilisateur, sans fichier intermédiaire.
5. Suppression du fichier temporaire : 10 minutes après le partage, au verrouillage et au démarrage. (L'application qui reçoit le fichier a besoin d'un moment pour le lire ; le supprimer immédiatement ferait échouer le partage.)
6. **Exporter mes données** (Paramètres) : mêmes étapes 1 à 3 pour chaque document, puis archive ZIP rangée par catégorie, préparée dans `secure_tmp/export/` par un isolate (chaque document déchiffré est ajouté puis effacé aussitôt). Sur Android, l'archive est copiée par petits morceaux vers l'emplacement choisi (sélecteur « Enregistrer sous » du système, code natif dans `MainActivity.kt`), sans passer par la mémoire ; sur iPhone, par la feuille de partage (« Enregistrer dans Fichiers », à vérifier sur iOS). Le dossier est supprimé dès la fin, réussie ou non. L'espace libre est contrôlé avant de commencer.
7. Un fichier dont l'empreinte ne correspond plus ne sort jamais : le partage, l'export ou l'archive s'arrêtent avec le message « fichier altéré ».

Code : `lib/core/documents/export_document.dart` (`DocumentExporter`), `lib/core/platform/share_service.dart`, parcours à l'écran dans `lib/features/documents/presentation/share/document_exit_flow.dart`.

---

## 13 bis. Sauvegarde chiffrée (choix D13)

1. **Créer** (Paramètres → Sauvegarde et synchronisation) : la clé de récupération doit avoir été notée (sinon l'application propose de le faire d'abord), puis nouvelle authentification.
2. Le fichier `.docsafe` (format `DSB1`) est une archive ZIP sans compression qui contient le coffre **tel qu'il est stocké, donc déjà chiffré** : la base (copiée dans une transaction de lecture, pour une copie cohérente), les documents et miniatures (DSF1), la serrure de récupération et un manifeste (format, date, nombre de documents, empreinte SHA-256 de chaque fichier ; aucun titre). **Rien n'est déchiffré pour sauvegarder.**
3. Le fichier est préparé dans `secure_tmp/backup/`, enregistré à l'emplacement choisi (même mécanisme que l'export), puis supprimé.
4. **Restaurer** (depuis l'accueil « J'ai une sauvegarde », ou depuis les réglages après nouvelle authentification) : la sauvegarde est décompressée à côté du coffre (`vault_restore/`) ; seuls les noms attendus sont acceptés et chaque empreinte est contrôlée. Un fichier étranger ou abîmé est refusé sans toucher au coffre.
5. La clé de récupération ouvre la serrure de la sauvegarde ; une clé fausse est refusée. L'utilisateur choisit ensuite un code pour ce téléphone. Alors seulement, l'ancien coffre est effacé et remplacé. La biométrie est désactivée (à réactiver dans les réglages).
6. Une sauvegarde s'ouvre avec la clé de récupération **en vigueur au moment où elle a été créée**. Après un changement de clé, il faut refaire une sauvegarde (indiqué à l'écran).

Code : `lib/core/backup/backup_service.dart`, `VaultService.restore`, écrans dans `lib/features/backup/`.

## 14. Notifications

- Entièrement locales : aucun serveur.
- **Texte générique par défaut**, sans le nom du document. Raisons : la notification apparaît sur l'écran verrouillé, et le système en conserve le texte en clair pour pouvoir la reprogrammer après un redémarrage.
- Option « Afficher le nom du document », désactivée par défaut.
- Toucher la notification ouvre DocSafe sur l'écran de déverrouillage, puis sur le document.
- Alarmes « inexactes » : un rappel peut arriver avec un léger décalage. En échange, aucune permission d'alarme exacte n'est nécessaire.
- L'autorisation d'envoyer des notifications est demandée **au moment où l'utilisateur ajoute sa première date d'expiration**, pas au lancement.
- Au plus 60 rappels sont programmés à l'avance (limite d'iOS : 64). Ils sont recalculés à chaque ouverture.

---

## 15. Écran, sauvegardes, journaux

**Écran**

- Android : `FLAG_SECURE` actif par défaut. Il bloque les captures et l'enregistrement d'écran et masque l'aperçu dans les applications récentes. Réglable dans les paramètres, après authentification.
- iOS (à vérifier sur iOS) : écran de masquage dès que l'application devient inactive. Les captures d'écran ne peuvent pas être bloquées sur iOS.

**Sauvegardes du système**

- Android : `allowBackup="false"` et règles d'extraction qui excluent tout (sauvegarde cloud et transfert d'appareil).
- iOS (à vérifier sur iOS) : dossier du coffre exclu de la sauvegarde iCloud ; éléments du trousseau limités à cet appareil.

**Journaux techniques**

- Un journal unique qui n'accepte que des codes d'événement et des types d'erreur. Jamais de titre, de chemin, de contenu, de clé.
- `print` et `debugPrint` interdits par les règles d'analyse.
- Aucun outil de statistiques ni de rapport de plantage dans le MVP.

---

## 16. Permissions

### Android

| Permission | Pourquoi | Moment de la demande |
|---|---|---|
| `CAMERA` | Scanner de secours (recadrage manuel) quand le scanner ML Kit n'est pas disponible. Le scanner ML Kit lui-même n'en a pas besoin. | Au premier scan concerné |
| `POST_NOTIFICATIONS` (Android 13+) | Rappels d'échéance | À la première date d'expiration |
| `RECEIVE_BOOT_COMPLETED` | Reprogrammer les rappels après un redémarrage | Automatique |
| `USE_BIOMETRIC` | Déverrouillage biométrique | Automatique |
| `VIBRATE` | Ajoutée par le paquet de notifications | Automatique |
| `INTERNET` | **Retirée de la version publiée** | — |

**Non demandées :** accès au stockage ou aux photos (les sélecteurs du système donnent accès au seul fichier choisi), localisation, contacts, microphone, alarmes exactes.

### iOS (à vérifier sur iOS)

| Clé `Info.plist` | Pourquoi |
|---|---|
| `NSCameraUsageDescription` | Numériser des documents |
| `NSFaceIDUsageDescription` | Déverrouiller le coffre avec Face ID |
| `NSPhotoLibraryUsageDescription` | Importer une image depuis la photothèque (si le sélecteur l'exige) |
| Notifications | Autorisation demandée à l'exécution |

---

## 17. Flux de données

```
  ENTRÉES                          COFFRE (sur le téléphone)              SORTIES VOLONTAIRES
  Appareil photo / scanner ──┐     ┌──────────────────────────────┐      ┌── Partage vers une application
  Fichiers ──────────────────┼────►│ fichiers chiffrés            │─────►├── Export vers un dossier choisi
  Galerie ───────────────────┤     │ base chiffrée                │      └── Sauvegarde chiffrée (voir D13)
  Partage depuis une appli ──┘     │ clés : stockage sécurisé     │
                                   └──────────────────────────────┘
                                   Aucun échange réseau
```

- **Aucune donnée ne quitte le téléphone** sans action explicite de l'utilisateur, précédée d'une authentification et d'un avertissement.
- **Scanner ML Kit :** il s'exécute sur le téléphone, dans les services Google Play. D'après la documentation de Google, les images ne sont pas envoyées à ses serveurs ; les bibliothèques ML Kit peuvent en revanche transmettre des statistiques techniques d'utilisation. Ce point sera revérifié et déclaré dans le formulaire « Sécurité des données » en phase 6.
- Le jour où une synchronisation sera ajoutée : fichiers chiffrés sur l'appareil avant tout envoi, consentement explicite, gestion des clés décrite dans ce document.

---

## 18. Effacement

| Action | Ce qui se passe |
|---|---|
| Supprimer un document | Ligne en base, fichier chiffré, miniature, rappels et notifications supprimés |
| Effacer le coffre (paramètres, après authentification et confirmation écrite) | Destruction des clés dans le stockage sécurisé, suppression de la base, des fichiers, des miniatures et des fichiers temporaires, annulation de toutes les notifications, retour à l'écran d'accueil |

Une fois les clés détruites, les éventuels restes de fichiers sur la mémoire du téléphone sont inexploitables : ils étaient chiffrés.

---

## 19. Limites connues

1. **Téléphone compromis pendant que le coffre est ouvert** (root, logiciel malveillant avec tous les droits) : la clé est en mémoire. Hors de portée de toute application.
2. **PIN à 6 chiffres :** un million de combinaisons. C'est solide tant que la serrure reste enfermée dans le stockage sécurisé du téléphone. Un attaquant capable d'extraire le contenu de ce stockage pourrait essayer tous les codes en dehors du téléphone. Recommandation affichée à l'utilisateur : activer aussi le verrouillage d'écran du téléphone.
3. **Effacement de la mémoire vive :** les clés sont écrasées au verrouillage, mais le langage Dart ne garantit pas qu'aucune copie ne subsiste un moment en mémoire.
4. **Suppression physique :** sur une mémoire flash, on ne peut pas garantir l'écrasement des blocs. Ce qui reste est chiffré.
5. **iOS :** les captures d'écran ne peuvent pas être bloquées, et tout le code propre à iOS reste à vérifier sur un appareil.
6. **Délai après des PIN erronés :** il peut être contourné en modifiant l'horloge du téléphone. Le calcul lent du PIN reste la vraie barrière.
7. **Fichiers en clair transitoires** (scanner, sélecteurs, partage), notamment sur Android 10 et antérieur (§12).
8. **Fichier partagé ou exporté :** il n'est plus protégé par DocSafe.
9. **Rappels :** leur ponctualité dépend du fabricant du téléphone ; leur texte est conservé en clair par le système.
10. **Pas de sauvegarde automatique :** téléphone perdu ou cassé = documents perdus, sauf sauvegarde faite par l'utilisateur (voir D13 dans [01-analyse.md](01-analyse.md)).
11. **Reconnaissance faciale sur Android :** souvent indisponible pour DocSafe (§6).
12. **Lecteur PDF :** composant complexe (PDFium), à garder à jour.
13. **Pas d'audit externe.** Recommandé avant une diffusion large.

---

## 20. Tests de sécurité prévus (phases 3 à 5)

| Exigence du cahier des charges (§10) | Vérification |
|---|---|
| Accès sans authentification | Toute route protégée renvoie à l'écran de déverrouillage. La base ne s'ouvre pas sans la bonne clé. |
| Mauvaise saisie du PIN | PIN faux refusé, compteur incrémenté, délais appliqués, compteur conservé après redémarrage |
| Verrouillage automatique | Passage en arrière-plan et inactivité (horloge simulée) → coffre verrouillé, clé absente |
| Chiffrement des fichiers | Les fichiers sur le disque ne contiennent ni signature PDF, JPEG ou PNG, ni le titre du document. La base est illisible avec un outil SQLite ordinaire. |
| Journaux | Capture des journaux pendant un parcours complet : aucune donnée sensible. Analyse statique : aucun `print`. |
| Fichiers temporaires | Dossier temporaire vide après import, scan, partage et verrouillage |
| Corruption de fichiers | Octet modifié, fichier tronqué, blocs échangés, fichiers intervertis → erreur d'intégrité, rien n'est affiché |
| Interruption d'une opération | Arrêt simulé à chaque étape de l'enregistrement → état cohérent après le contrôle |

Vérifications manuelles sur l'APK final : permissions réellement présentes, sauvegarde du système vide, capture d'écran bloquée, aperçu des applications récentes masqué.
