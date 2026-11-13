# DocuSafe – consignes pour Claude

Application mobile Flutter : coffre-fort de documents **chiffré** et **hors ligne**, Android d'abord, iPhone ensuite avec le même code.
Le document de référence est [docs/cahier-des-charges.md](docs/cahier-des-charges.md) : en cas de doute, il prime.

## Le développeur

- Il écrit en français. Lui répondre en **français simple**, avec des phrases courtes, et expliquer chaque terme technique la première fois.
- Il travaille sous Windows 11 avec VS Code et Android Studio, sans Mac. Les commandes qu'il doit lancer lui-même sont données pour **PowerShell**.

## Méthode imposée (cahier des charges §0.3 et §13)

- Le projet avance par phases. **Avant** une phase : annoncer ce qui va être fait. **Après** : résumer, lister les fichiers créés ou modifiés, donner les commandes à lancer.
- **Attendre la validation du développeur avant de passer à la phase suivante.**
- Tenir à jour le tableau d'avancement de [README.md](README.md) et [docs/problemes-connus.md](docs/problemes-connus.md).
- Chaque session en ligne travaille sur sa propre branche : rappeler au développeur de créer puis de fusionner la pull request.

## Avancement au 13/11/2026

| Phase | État |
|---|---|
| 1 – Analyse et conception | Validée |
| 2 – Design (système de design, 46 maquettes) | Terminée, **en attente de validation** |
| 3 – Socle : projet Flutter, chiffrement, base de données, authentification | Pas commencée |
| 4 à 6 – Fonctionnalités, sécurité et optimisation, publication | À venir |

Il n'existe encore **aucun code Flutter** : le dépôt contient la documentation et les maquettes.

## À lire avant d'écrire du code

| Sujet | Document |
|---|---|
| Choix retenus (D1 à D18) et risques | [docs/01-analyse.md](docs/01-analyse.md) |
| Architecture, dossiers, navigation, tests | [docs/02-architecture.md](docs/02-architecture.md) |
| Tables, contraintes, fichiers sur le téléphone | [docs/03-modele-de-donnees.md](docs/03-modele-de-donnees.md) |
| Clés, PIN, chiffrement, verrouillage, permissions | [docs/04-securite.md](docs/04-securite.md) |
| Parcours écran par écran | [docs/05-parcours-utilisateurs.md](docs/05-parcours-utilisateurs.md) |
| Paquets retenus et versions | [docs/06-dependances.md](docs/06-dependances.md) |
| Couleurs exactes, typographie, composants | [docs/07-design.md](docs/07-design.md) et [docs/maquettes/index.html](docs/maquettes/index.html) |

## Choix structurants

- Flutter 3.50 / Dart 3.14. Android : `minSdk` 24, `compileSdk` 37, `targetSdk` 36. iOS 15.
- Identifiant de l'application : `com.docusafe.app` (modifiable jusqu'à la création du projet, définitif après publication). Paquet Dart : `docusafe`.
- Riverpod sans génération de code, go_router, drift.
- Base entièrement chiffrée avec **SQLite3MultipleCiphers**, activé par les hooks du paquet `sqlite3` dans `pubspec.yaml` (`hooks` → `user_defines` → `sqlite3` → `source: sqlite3mc`). Ne pas utiliser `sqlcipher_flutter_libs`, `sqlite3_flutter_libs` ni `drift_flutter`.
- Scanner : `cunning_document_scanner` (ML Kit sur Android, VisionKit sur iOS, repli intégré).
- Fichiers chiffrés en AES-256-GCM par blocs de 1 Mo (format `DSF1`). Code PIN de 6 chiffres minimum dérivé avec Argon2id. Clé de récupération. Biométrie liée au Keystore à partir d'Android 9.
- Aucune permission `INTERNET` dans l'application publiée. Notifications au texte générique, alarmes inexactes.
- Sauvegarde chiffrée manuelle incluse dans le MVP.
- Textes en fichiers ARB (français seul). Identifiants de code en anglais ; commentaires et documentation en français.
- Couleurs : recopier les valeurs de `docs/07-design.md`, ne pas les recalculer.
- Versions des paquets vérifiées le 13/11/2026 : les revérifier sur pub.dev avant de les ajouter.

## Règles de qualité (cahier des charges §14)

- Aucune fonctionnalité simulée, aucun bouton sans action, aucune donnée fictive en production.
- `flutter analyze` sans erreur ni avertissement.
- Jamais de `print` ou `debugPrint` contenant des données de documents.
- Tout code propre à iOS qui n'a pas pu être testé est marqué « à vérifier sur iOS ».

## Environnements

- **PC du développeur : infecté par un virus (Expiro) depuis le 13/11/2026.** Flutter y est inutilisable tant que le PC n'est pas nettoyé. Ne jamais conseiller de désactiver Microsoft Defender, d'ajouter une exclusion ou de restaurer un fichier signalé. Voir [docs/problemes-connus.md](docs/problemes-connus.md).
- **Session en ligne (claude.ai/code)** : machine Ubuntu 24.04. Le SDK Flutter n'est pas dans le dépôt : l'installer au début de la phase 3 (archive Linux officielle, empreinte SHA-256 vérifiée). `flutter analyze` et `flutter test` y fonctionnent ; l'émulateur et le téléphone, non. Le SDK Android (téléchargé depuis dl.google.com) peut exiger d'élargir l'accès réseau de l'environnement.
- Les tests sur téléphone se feront sur le PC une fois nettoyé, ou avec un APK compilé dans le cloud.
