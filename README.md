 # DocuSafe

Coffre-fort documentaire pour téléphone, développé avec Flutter. Les documents restent sur l'appareil, chiffrés, et l'application fonctionne sans connexion Internet.

Android en priorité (MVP), puis iPhone avec le même code.

> **Attention – 13/11/2026 :** le PC de développement est infecté par un virus. Flutter ne peut pas fonctionner tant que le PC n'est pas nettoyé. Voir [docs/problemes-connus.md](docs/problemes-connus.md).

## État d'avancement

| Phase | Contenu | État |
|---|---|---|
| 1 – Analyse et conception | Architecture, modèle de données, parcours, règles de sécurité | Validée le 13/11/2026 |
| 2 – Design | Système de design, maquettes, navigation | Validée le 13/11/2026 |
| 3 – Socle | Projet Flutter, chiffrement, base de données, authentification | Validée le 14/11/2026 |
| 4 – Fonctionnel, lot a | Importation, documents (liste, fiche, lecture, modification, favoris, suppression), catégories, navigation, paramètres | Validé le 14/11/2026 |
| 4 – Fonctionnel, lot b | Scanner (aperçu, pages, PDF), recherche avec filtres | Validé le 14/11/2026 |
| 4 – Fonctionnel, lot c | Échéances et notifications · partage, export · sauvegarde, stockage · profil local | Terminé le 15/11/2026 |
| 5 – Sécurité et optimisation | Tests de sécurité, corrections, analyse des risques, optimisation ([docs/08-tests-et-risques.md](docs/08-tests-et-risques.md)) | **En cours** depuis le 15/11/2026 |
| 6 – Publication | Builds, fiches des magasins, documents légaux | À venir |

## Voir l'application sur un téléphone

À chaque envoi de code, GitHub compile une version de test Android et la publie dans la page **Releases** (étiquette `apercu`). Mode d'emploi : [docs/apercu-telephone.md](docs/apercu-telephone.md).

## Voir les maquettes

Ouvrir `docs\maquettes\index.html` dans un navigateur, ou dans le terminal :

```powershell
start docs\maquettes\index.html
```

## Documentation

| Document | Contenu |
|---|---|
| [docs/cahier-des-charges.md](docs/cahier-des-charges.md) | Cahier des charges de référence (version 1.1) |
| [docs/01-analyse.md](docs/01-analyse.md) | Analyse, choix retenus, risques |
| [docs/02-architecture.md](docs/02-architecture.md) | Organisation du code, modules, navigation |
| [docs/03-modele-de-donnees.md](docs/03-modele-de-donnees.md) | Tables, relations, fichiers sur le téléphone |
| [docs/04-securite.md](docs/04-securite.md) | Règles de sécurité, analyse des risques, limites |
| [docs/05-parcours-utilisateurs.md](docs/05-parcours-utilisateurs.md) | Parcours de l'utilisateur, écran par écran |
| [docs/06-dependances.md](docs/06-dependances.md) | Paquets retenus et justification |
| [docs/07-design.md](docs/07-design.md) | Système de design : couleurs, typographie, composants, navigation |
| [docs/maquettes/index.html](docs/maquettes/index.html) | Maquettes des 46 écrans, en clair et en sombre |
| [docs/captures/index.html](docs/captures/index.html) | Captures d'écran réelles des 12 écrans de la phase 3, Android et iPhone, en clair et en sombre |
| [docs/guide-installation-windows.md](docs/guide-installation-windows.md) | Installation de l'environnement de développement |
| [docs/problemes-connus.md](docs/problemes-connus.md) | Problèmes connus |

## Démarrer

### Sur le PC (Windows, une fois le PC nettoyé)

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter run
```

La première compilation Android télécharge le moteur SQLite chiffré (connexion Internet nécessaire).

### Dans une session en ligne (Ubuntu)

```bash
bash tool/setup_cloud.sh
export PATH="/home/user/sdk/flutter/bin:$PATH"
flutter analyze && flutter test
```

Le script installe Flutter 3.50.0 (empreinte vérifiée), récupère les paquets et génère le code de la base. Pour régénérer les captures d'écran : `DOCUSAFE_SCREENSHOTS=1 flutter test test/screenshots --update-goldens` (ajouter `DOCUSAFE_PLATFORM=ios` pour le rendu iPhone). L'émulateur, le téléphone et la compilation d'un APK ne sont pas disponibles dans la session en ligne (voir [docs/problemes-connus.md](docs/problemes-connus.md), P3).

## Organisation du code

| Dossier | Contenu |
|---|---|
| `lib/app/` | Thème, textes (ARB), routeur, écran de démarrage |
| `lib/core/security/` | Chiffrement (AES-256-GCM, format `DSF1`), clés et serrures, code PIN, biométrie, verrouillage |
| `lib/core/database/` | Base drift chiffrée (SQLite3MultipleCiphers), index de recherche FTS5, DAO |
| `lib/core/storage/` | Emplacements des fichiers sur le téléphone |
| `lib/core/widgets/` | Composants réutilisables du système de design |
| `lib/core/documents/` | Formats acceptés, ingestion (`IngestDocument`), ouverture, suppression, dépôt des documents |
| `lib/core/platform/` | Scanner, sélecteurs de fichiers et photos, miniatures (interfaces + versions simulées) |
| `lib/features/` | Écrans par module : onboarding, auth, dashboard, documents (liste, fiche, lecture, modification, importation, suppression), scanner, search, categories, settings, legal |
| `test/fixtures/` | Fichiers de test (PDF, PNG, texte) |
| `test/` | Tests unitaires et tests de widgets |
| `tool/` | Scripts d'installation |
