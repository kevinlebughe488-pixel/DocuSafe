# DocSafe – consignes pour Claude

Application mobile Flutter **DocSafe** (nom corrigé le 15/11/2026 : jamais « DocuSafe » dans un texte visible ; les identifiants internes `docusafe` restent) : coffre-fort de documents **chiffré** et **hors ligne**, Android d'abord, iPhone ensuite avec le même code.
Le document de référence est [docs/cahier-des-charges.md](docs/cahier-des-charges.md) : en cas de doute, il prime.

## Le développeur

- Il écrit en français. Lui répondre en **français simple**, avec des phrases courtes, et expliquer chaque terme technique la première fois.
- Il travaille sous Windows 11 avec VS Code et Android Studio, sans Mac. Les commandes qu'il doit lancer lui-même sont données pour **PowerShell**.

## Méthode imposée (cahier des charges §0.3 et §13)

- Le projet avance par phases. **Avant** une phase : annoncer ce qui va être fait. **Après** : résumer, lister les fichiers créés ou modifiés, donner les commandes à lancer.
- **Attendre la validation du développeur avant de passer à la phase suivante.**
- Tenir à jour le tableau d'avancement de [README.md](README.md) et [docs/problemes-connus.md](docs/problemes-connus.md).
- Chaque session en ligne travaille sur sa propre branche : rappeler au développeur de créer puis de fusionner la pull request.

## Avancement au 15/11/2026

| Phase | État |
|---|---|
| 1 – Analyse et conception | Validée |
| 2 – Design (système de design, 46 maquettes) | Validée |
| 3 – Socle : projet Flutter, chiffrement, base de données, authentification | Validée le 14/11/2026 |
| 4 – lot a : importation, documents, catégories, navigation, paramètres | Validé le 14/11/2026 |
| 4 – lot b : scanner, recherche | Validé le 14/11/2026 |
| 4 – lot c : échéances et notifications, partage et export, sauvegarde et stockage, profil local | Terminé le 15/11/2026 (le développeur a demandé d'enchaîner) |
| 5 – Sécurité et optimisation : tests de sécurité, corrections, analyse des risques | Terminée le 15/11/2026 (le développeur a demandé d'enchaîner) |
| 6 – Publication : icône, contrôles, AAB, iOS, dossier de soumission, essais sur téléphones | **En cours** |

Le code Flutter existe (`lib/`, `test/`, `android/`, `ios/`). Dans une session en ligne, lancer d'abord `bash tool/setup_cloud.sh` puis `export PATH="/home/user/sdk/flutter/bin:$PATH"`.

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
| Matrice de tests, défauts corrigés, risques à jour | [docs/08-tests-et-risques.md](docs/08-tests-et-risques.md) |
| Publication : signature, fiches des magasins, essais sur téléphones | [docs/publication/README.md](docs/publication/README.md) |
| Conformité au cahier des charges, exigence par exigence | [docs/09-conformite.md](docs/09-conformite.md) |

## Choix structurants

- Flutter 3.50 / Dart 3.14. Android : `minSdk` 24, `compileSdk` 37, `targetSdk` 36. iOS 15.
- Depuis Flutter 3.50, `package:flutter/material.dart` est déprécié : importer `package:material_ui/material_ui.dart` (et `package:cupertino_ui/cupertino_ui.dart` pour les éléments iOS). Les deux paquets sont publiés par flutter.dev.
- Identifiant de l'application (Android `applicationId`, iOS `PRODUCT_BUNDLE_IDENTIFIER`) : `com.docsafe.app` (changé le 15/11/2026, définitif après publication). Restent internes : espace de noms Kotlin `com.docusafe.app`, paquet Dart `docusafe`.
- Riverpod sans génération de code, go_router, drift.
- Base entièrement chiffrée avec **SQLite3MultipleCiphers**, activé par les hooks du paquet `sqlite3` dans `pubspec.yaml` (`hooks` → `user_defines` → `sqlite3` → `source: sqlite3mc`). Ne pas utiliser `sqlcipher_flutter_libs`, `sqlite3_flutter_libs` ni `drift_flutter`.
- Scanner : `cunning_document_scanner` (ML Kit sur Android, VisionKit sur iOS, repli intégré).
- Chiffrement **en Dart pur** (`DartAesGcm`, `DartHkdf`, `DartHmac`, `DartArgon2id` nommés explicitement dans `DartCryptoEngine`). Ne pas réintroduire `cryptography_flutter` : son HMAC natif fait échouer la création du coffre sur Android.
- Fichiers chiffrés en AES-256-GCM par blocs de 1 Mo (format `DSF1`). Code PIN de 6 chiffres minimum dérivé avec Argon2id. Clé de récupération créée en silence, proposée par un rappel sur l'accueil (D6 révisée le 14/11/2026). Biométrie liée au Keystore à partir d'Android 9 ; mots « Face ID » / « Touch ID » sur iPhone.
- Aucune permission `INTERNET` dans l'application publiée. Notifications au texte générique, alarmes inexactes.
- Sauvegarde chiffrée manuelle incluse dans le MVP.
- Textes en fichiers ARB (français seul) dans `lib/app/l10n/app_fr.arb`, classe générée `AppLocalizations` (régénérée par `flutter pub get`). Identifiants de code en anglais ; commentaires et documentation en français.
- Après toute modification des tables drift : `dart run build_runner build`.
- Tests de widgets : utiliser `test/support/test_app.dart` (stockage sécurisé en mémoire, base ouverte dans l'isolate du test, Argon2id léger). Toute entrée-sortie réelle dans le corps d'un test (copie de fichier, création de dossier) doit être faite dans `tester.runAsync`, sinon le test se fige. Ne pas utiliser `pumpAndSettle` (animations sans fin) : utiliser `settle()`. Pour ajouter des documents dans un test de widgets, créer et ouvrir le coffre hors de l'interface (`tester.runAsync` + `unlockWithPin`, voir `test/features/deadlines_flow_test.dart`) : une base ouverte par l'interface du test se bloque avec les isolates. Dans le code appelé depuis l'interface, lire la base avec des requêtes simples (`get()`) et non `watch(...).first`, qui se fige dans les tests. Revenir en arrière avec `routerProvider.pop()` (`pageBack` ne reconnaît pas le bouton de `material_ui`).
- Écrans avec le clavier du code : tester aussi en petit écran (`useSmallPhoneSize`, 320 × 640 points). Ne jamais utiliser `ref` dans `dispose()` : lire le service dans un champ `late final` avant.
- L'écran « Code oublié » s'ouvre avec `context.go(Routes.lockRecovery)` (pas `push`) : le routeur le laisse affiché après le déverrouillage par la clé, jusqu'au choix du nouveau code.
- Accessibilité : tester les nouveaux écrans à 200 % (`test/features/large_text_test.dart`).
- Dans un `ref.listen(vaultControllerProvider, …)`, ne pas lire un fournisseur lié à la session (base, rappels…) : il peut encore renvoyer la session précédente. Utiliser `next.session`.
- Une fermeture envoyée à `Isolate.run` depuis une méthode qui a la base ou la session à portée doit être créée dans une fonction de premier niveau (sinon la base est capturée et l'envoi échoue).
- Tout ajout de document passe par `IngestDocument` (`lib/core/documents/`) : ne jamais écrire un fichier dans le coffre autrement. Le scanner assemble ses pages en PDF (`PdfBuilder`) puis rejoint l'importation (`ImportViewModel.addScannedPdf`) ; ses images sont copiées dans `secure_tmp/` et son dossier est vidé aussitôt (`ScannerService.cleanCache`). Le lecteur PDF, les sélecteurs, le partage et « Partager vers DocSafe » sont derrière des interfaces (`ThumbnailService`, `FilePickerService`, `ShareService`, `ShareIntakeService`) avec des versions simulées pour les tests.
- Couleurs : recopier les valeurs de `docs/07-design.md`, ne pas les recalculer.
- Versions des paquets vérifiées le 13/11/2026 : les revérifier sur pub.dev avant de les ajouter.

## Règles de qualité (cahier des charges §14)

- Aucune fonctionnalité simulée, aucun bouton sans action, aucune donnée fictive en production.
- `flutter analyze` sans erreur ni avertissement.
- Jamais de `print` ou `debugPrint` contenant des données de documents.
- Tout code propre à iOS qui n'a pas pu être testé est marqué « à vérifier sur iOS ».

## Environnements

- **PC du développeur : infecté par un virus (Expiro) depuis le 13/11/2026.** Flutter y est inutilisable tant que le PC n'est pas nettoyé. Ne jamais conseiller de désactiver Microsoft Defender, d'ajouter une exclusion ou de restaurer un fichier signalé. Voir [docs/problemes-connus.md](docs/problemes-connus.md).
- **Session en ligne (claude.ai/code)** : machine Ubuntu 24.04. Le SDK Flutter n'est pas dans le dépôt : `bash tool/setup_cloud.sh` l'installe dans `/home/user/sdk/flutter` (archive Linux officielle, empreinte SHA-256 vérifiée, environ 2 minutes). `flutter analyze` et `flutter test` y fonctionnent ; l'émulateur et le téléphone, non. L'hôte `dl.google.com` (SDK Android, dépôt Maven de Google) est bloqué par le réseau de l'environnement : aucun APK ne peut y être compilé (voir docs/problemes-connus.md, P3).
- **Aperçu sur téléphone** : `.github/workflows/apercu-android.yml` compile un APK (`DOCUSAFE_APERCU=1` : identifiant `com.docsafe.app.apercu`, clé de test `android/app/apercu.keystore`) à chaque envoi et le publie dans la release `apercu`. Mode d'emploi : docs/apercu-telephone.md. Le job « emulateur » lance ensuite `tool/smoke_test.py` sur un émulateur Android à petit écran (création du coffre, verrouillage, réouverture, relance) : son verdict est à la fin du journal du job. Après un envoi, vérifier que la compilation **et** ce test réussissent. Tests d'intégration : `integration_test/` (recette « Tests d'intégration », sur pull request ou à la demande). Couverture : `flutter test --coverage --exclude-tags screenshots` puis `python3 tool/coverage_report.py coverage/lcov.info > docs/rapport-couverture.md`. Recettes de phase 6 : « Publication Android » (AAB, `tool/check_apk.py` bloquant : aucune permission réseau, 16 Ko…) et « Compilation iOS » (Mac de GitHub, sans signature ; minutes de Mac comptées dix fois). Icônes : `tool/generate_icons.py` (ne pas retoucher les PNG à la main). Signature : clé d'envoi dans les secrets GitHub ou `android/key.properties`, jamais sur le PC infecté. Les journaux GitHub ne sont pas téléchargeables depuis la session (hôte bloqué) : les lire avec l'outil `get_job_logs` (`return_content`, grand `tail_lines`), qui les enregistre dans un fichier à fouiller.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- graphify-out/ n'est pas versionné : le graphe est reconstruit au démarrage de chaque session par `tool/graphify_bootstrap.sh` (hook SessionStart), qui installe aussi graphify s'il manque. Exclusions dans `.graphifyignore`.
