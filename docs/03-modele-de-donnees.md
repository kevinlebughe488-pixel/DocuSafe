# Modèle de données

Document rédigé le 13/11/2026 (phase 1).

La base est une base **SQLite entièrement chiffrée**, gérée avec `drift`. Elle n'est lisible que lorsque le coffre est déverrouillé.

---

## 1. Vue d'ensemble

```
  categories 1 ────< documents >────< document_tags >──── tags
                         │ 1
                         └────< reminders

  vault_settings   (une seule ligne : les réglages)
  documents_fts    (index de recherche : une ligne par document)
```

Lecture : une catégorie contient plusieurs documents ; un document a plusieurs tags et plusieurs rappels.

Les champs marqués **(ajout)** ne figurent pas dans le cahier des charges. Ils sont nécessaires à des fonctions qu'il demande ; la raison est indiquée à chaque fois.

---

## 2. Tables

### 2.1. `documents`

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | texte | clé primaire | Identifiant unique (UUID) |
| `title` | texte | obligatoire, non vide, 200 caractères max | Nom du document |
| `doc_type` | texte | facultatif | **(ajout)** Type de document : « Passeport », « Diplôme »… Demandé par la fiche descriptive (§3.6), absent du modèle (§4.3). |
| `category_id` | texte | obligatoire, référence `categories.id`, suppression **interdite** tant que des documents y sont rattachés | Catégorie |
| `file_name` | texte | obligatoire | Nom du fichier d'origine (pour l'export) |
| `encrypted_file_path` | texte | obligatoire, unique | Chemin **relatif** du fichier chiffré dans le coffre |
| `file_type` | texte | obligatoire, valeurs : `pdf`, `jpeg`, `png` | Format |
| `file_size` | entier | obligatoire, ≥ 0 | Taille du fichier d'origine, en octets |
| `page_count` | entier | facultatif | **(ajout)** Nombre de pages, affiché sur la fiche |
| `created_at` | date-heure | obligatoire | Date d'ajout |
| `updated_at` | date-heure | obligatoire | Date de modification |
| `last_opened_at` | date-heure | facultatif | **(ajout)** Dernière consultation. Nécessaire pour « Documents consultés récemment » (§3.11). |
| `issue_date` | date | facultatif | Date d'émission |
| `expiration_date` | date | facultatif | Date d'expiration |
| `description` | texte | facultatif | Description |
| `is_favorite` | booléen | obligatoire, faux par défaut | Favori |
| `content_index` | texte | facultatif | Texte extrait par OCR (vide dans le MVP) |
| `integrity_hash` | texte | obligatoire | Empreinte SHA-256 du fichier d'origine |

### 2.2. `categories`

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | texte | clé primaire | Identifiant |
| `name` | texte | obligatoire, 40 caractères max | Nom affiché |
| `name_key` | texte | obligatoire, **unique** | **(ajout)** Nom simplifié (minuscules, sans accents). Empêche de créer « Santé » et « sante ». |
| `icon` | texte | obligatoire | Nom d'une icône de la liste proposée |
| `color` | entier | obligatoire | Couleur |
| `created_at` | date-heure | obligatoire | Date de création |
| `sort_order` | entier | obligatoire, 0 par défaut | **(ajout)** Ordre d'affichage |
| `is_system` | booléen | obligatoire, faux par défaut | **(ajout)** Vrai pour « Autres », qui ne peut pas être supprimée |

Catégories créées avec le coffre : **Identité, Éducation, Professionnel, Finances, Immobilier, Santé, Autres**. Leurs identifiants sont fixes (`default-identity`, `default-education`…) pour éviter les doublons le jour où deux appareils seront synchronisés. Icônes et couleurs seront choisies en phase 2.

### 2.3. `tags`

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | texte | clé primaire | Identifiant |
| `name` | texte | obligatoire, 30 caractères max | Nom affiché |
| `name_key` | texte | obligatoire, **unique** | **(ajout)** Nom simplifié, même principe que pour les catégories |

### 2.4. `document_tags`

| Colonne | Type | Contraintes |
|---|---|---|
| `document_id` | texte | référence `documents.id`, suppression en cascade |
| `tag_id` | texte | référence `tags.id`, suppression en cascade |

Clé primaire : le couple (`document_id`, `tag_id`). Un tag ne peut donc pas être posé deux fois sur le même document.

### 2.5. `reminders`

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | texte | clé primaire | Identifiant |
| `document_id` | texte | obligatoire, référence `documents.id`, suppression en cascade | Document concerné |
| `reminder_date` | date-heure | obligatoire | Moment où la notification doit s'afficher |
| `is_enabled` | booléen | obligatoire, vrai par défaut | Rappel actif ou non |
| `offset_days` | entier | obligatoire | **(ajout)** Nombre de jours avant l'expiration (90, 30, 7, 0). Permet de recalculer le rappel quand la date d'expiration change et d'afficher « 30 jours avant ». |
| `notification_id` | entier | obligatoire, unique | **(ajout)** Numéro de la notification côté système. Indispensable pour l'annuler ou la reprogrammer. |

Un seul rappel par document et par délai : le couple (`document_id`, `offset_days`) est unique.

### 2.6. `vault_settings`

Une seule ligne (`id` = 1).

| Colonne | Type | Valeur par défaut | Rôle |
|---|---|---|---|
| `id` | entier | 1 | Clé primaire |
| `biometric_enabled` | booléen | faux | Biométrie activée |
| `auto_lock_duration` | entier | 120 | Délai de verrouillage après inactivité, en secondes |
| `notifications_enabled` | booléen | vrai | Rappels activés |
| `vault_configuration` | texte (JSON) | `{}` | Autres réglages : délais de rappel par défaut (90, 30, 7, 0), heure des rappels (09:00), affichage du nom dans les notifications, captures d'écran autorisées, nom du profil local |

**Pourquoi certains réglages existent aussi en dehors de la base :** la base est fermée tant que le coffre est verrouillé. Or l'écran de déverrouillage doit savoir si la biométrie est activée et s'il faut bloquer les captures d'écran. Ces quelques indicateurs (qui ne sont pas des secrets) sont donc recopiés dans le stockage sécurisé du système. Détail dans [04-securite.md](04-securite.md).

### 2.7. `documents_fts` – index de recherche

Table spéciale de SQLite (FTS5) qui permet une recherche instantanée, même avec des milliers de documents.

| Colonne indexée | Source |
|---|---|
| `title` | Nom du document |
| `doc_type` | Type de document |
| `description` | Description |
| `tags` | Tags du document, réunis |
| `file_name` | Nom du fichier d'origine |
| `content` | Texte OCR (`content_index`), quand il existera |

- La recherche **ignore les majuscules et les accents** : « diplome » trouve « Diplôme ».
- La recherche fonctionne **dès les premières lettres** : « pass » trouve « Passeport ».
- L'index est mis à jour dans la même transaction que le document, donc il ne peut pas se désynchroniser.
- Comme il se trouve dans la base chiffrée, **l'index est chiffré lui aussi**. C'est ce qui protège le texte OCR (exigence du §4.3).

Les autres critères du cahier des charges (catégorie, dates, favoris, format) sont des filtres classiques combinés à cette recherche.

---

## 3. Règles d'intégrité

| Règle | Mise en œuvre |
|---|---|
| Un document appartient toujours à une catégorie existante | Clé étrangère obligatoire |
| Supprimer une catégorie ne supprime jamais ses documents | La base **refuse** la suppression tant qu'il reste des documents. L'application les déplace d'abord (par défaut vers « Autres »), dans la même transaction. |
| « Autres » existe toujours | `is_system` : suppression refusée par l'application |
| Supprimer un document supprime ses tags associés et ses rappels | Suppression en cascade |
| Pas de titre vide, pas de taille négative, format connu | Contraintes de vérification dans la base |
| Pas de doublon de catégorie ou de tag | Colonne `name_key` unique |
| Opérations en plusieurs étapes | Toujours dans une transaction : tout réussit ou rien ne change |

Les clés étrangères sont activées à l'ouverture de la base.

### Suppression d'un document, dans l'ordre

1. Transaction en base : le document, ses liens de tags, ses rappels et sa ligne d'index disparaissent ensemble.
2. Annulation des notifications programmées.
3. Suppression du fichier chiffré et de la miniature.

Si l'étape 3 échoue (stockage indisponible), le document a déjà disparu pour l'utilisateur et le fichier orphelin sera supprimé par le contrôle de cohérence au prochain déverrouillage.

---

## 4. Dates et identifiants

| Sujet | Choix | Raison |
|---|---|---|
| Identifiants | UUID générés par l'application | Pas de collision entre deux appareils : prêt pour une future synchronisation |
| Date-heure (`created_at`…) | Instant en temps universel (UTC) | Tri fiable, quel que soit le fuseau horaire |
| Date seule (`issue_date`, `expiration_date`) | Texte `AAAA-MM-JJ`, **sans heure ni fuseau** | Un passeport qui expire le 12 mars expire le 12 mars partout. Stocker une heure ferait glisser la date d'un jour en voyage. |
| Chemins de fichiers | Relatifs au dossier du coffre | Sur iOS, le chemin absolu de l'application change à chaque mise à jour |

---

## 5. Index (performance)

Pour que les listes restent rapides sur un téléphone modeste :

| Index | Sert à |
|---|---|
| `documents(category_id)` | Liste par catégorie, compteurs du tableau de bord |
| `documents(created_at)` | Récemment ajoutés |
| `documents(last_opened_at)` | Récemment consultés |
| `documents(expiration_date)` | Onglet Échéances |
| `documents(is_favorite)` | Favoris |
| `documents(integrity_hash)` | Détection d'un doublon à l'importation |
| `reminders(reminder_date)` | Prochains rappels à programmer |
| `document_tags(tag_id)` | Documents d'un tag |

---

## 6. Où sont les données sur le téléphone

```
Dossier privé de l'application (inaccessible aux autres applications)
└── vault/
    ├── docusafe.db              Base de données chiffrée
    ├── recovery.slot            Clé du coffre, protégée par la clé de récupération
    ├── files/ab/<id>.dsf        Documents chiffrés
    └── thumbs/ab/<id>.dst       Miniatures chiffrées
└── vault_restore/               Sauvegarde décompressée, le temps d'une restauration
                                 (déjà chiffrée ; remplace vault/ à la fin)

Dossier cache privé
└── secure_tmp/                  Fichiers temporaires (partage, export, sauvegarde en
                                 préparation), purgés au verrouillage et au démarrage

Stockage sécurisé du système (Android Keystore / Trousseau iOS)
└── Clé du coffre protégée par le PIN, clé liée à la biométrie, compteur de tentatives
```

`ab` représente les deux premiers caractères de l'identifiant : les fichiers sont répartis dans des sous-dossiers pour éviter un dossier unique trop volumineux.

**Séparation des clés et des données** (exigence du §3.7) : les fichiers et la base sont dans le dossier de l'application ; les clés sont dans le stockage sécurisé du système. Le fichier `recovery.slot` fait exception, sans risque : il est inutilisable sans la clé de récupération, qui n'est stockée nulle part sur le téléphone.

---

## 7. Entités du domaine

Classes Dart **immuables** : `Document`, `Category`, `Tag`, `Reminder`, `VaultSettings`, plus deux types de valeur : `DocumentFileType` (pdf, jpeg, png) et `DateOnly` (date sans heure). `DocumentTag` n'existe que comme table : dans le code, un document porte simplement sa liste de tags.

---

## 8. Évolution du schéma

- Version actuelle du schéma : **1**.
- Chaque changement futur passera par une **migration** qui conserve les données. Un instantané du schéma est enregistré à chaque version, et un test vérifie le passage de chaque ancienne version à la nouvelle.
- Évolutions déjà envisagées, toutes réalisables par migration : sous-catégories (`parent_id`), suivi des suppressions et état de synchronisation.
