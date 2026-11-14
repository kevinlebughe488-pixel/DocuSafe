# Dépendances (paquets pub.dev)

Document rédigé le 13/11/2026 (phase 1).

Le cahier des charges demande de vérifier, avant d'ajouter un paquet, qu'il est **maintenu**, **compatible avec la version stable de Flutter**, qu'il **couvre Android et iOS** et que sa **licence permet un usage commercial**. Ces quatre points ont été contrôlés le 13/11/2026 auprès de pub.dev, en lisant la documentation de la version exacte de chaque paquet.

Référence : **Flutter 3.50.0 / Dart 3.14** (stable du 11/11/2026). Aucun paquet retenu n'est abandonné ni visé par un avis de sécurité à cette date.

Les versions seront figées dans `pubspec.lock` au moment de l'installation (phase 3).

---

## 1. Paquets retenus pour le MVP

### Interface

| Paquet | Version | Rôle | Licence | Éditeur |
|---|---|---|---|---|
| `material_ui` | 1.11.0 | Widgets Material 3. Depuis Flutter 3.50, `package:flutter/material.dart` est déprécié au profit de ce paquet. | BSD-3 | flutter.dev |
| `cupertino_ui` | 1.1.6 | Widgets et textes iOS (transitions, `GlobalCupertinoLocalizations`) | BSD-3 | flutter.dev |

### Structure de l'application

| Paquet | Version | Rôle | Licence | Éditeur |
|---|---|---|---|---|
| `flutter_riverpod` | 3.5.0 | Gestion d'état et injection des services | MIT | dash-overflow.net |
| `go_router` | 18.1.4 | Navigation et redirections (verrouillage) | BSD-3 | flutter.dev |
| `intl` + `flutter_localizations` | 0.20.3 / SDK | Textes traduisibles, formats de date | BSD-3 | dart.dev |

### Données

| Paquet | Version | Rôle | Licence | Éditeur |
|---|---|---|---|---|
| `drift` | 2.35.4 | Base de données SQLite typée, requêtes observées | MIT | simonbinder.eu |
| `sqlite3` | 3.9.1 | Moteur SQLite, avec le chiffrement **SQLite3MultipleCiphers** | MIT | simonbinder.eu |
| `path_provider` | 2.1.6 | Emplacement des dossiers privés de l'application | BSD-3 | flutter.dev |
| `path` | 1.9.1 | Manipulation des chemins de fichiers | BSD-3 | dart.dev |

### Sécurité

| Paquet | Version | Rôle | Licence | Éditeur |
|---|---|---|---|---|
| `cryptography` | 2.9.0 | AES-256-GCM, HKDF, Argon2id | Apache-2.0 | dint.dev |
| `cryptography_flutter` | 2.3.4 | Accélération native de `cryptography` | Apache-2.0 | dint.dev |
| `crypto` | 3.0.8 | Empreinte SHA-256 calculée au fil de la lecture | BSD-3 | dart.dev |
| `flutter_secure_storage` | 11.2.0 | Android Keystore et Trousseau iOS, zone protégée par biométrie | BSD-3 | steenbakker.dev |
| `local_auth` | 3.0.2 | Détection de la biométrie, confirmation des opérations sensibles | BSD-3 | flutter.dev |

### Documents

| Paquet | Version | Rôle | Licence | Éditeur |
|---|---|---|---|---|
| `cunning_document_scanner` | 3.1.0 | Scanner : ML Kit (Android), VisionKit (iOS), repli à recadrage manuel | MIT | victorcarreras.dev |
| `file_picker` | 13.3.3 | Choix d'un fichier (PDF, images), enregistrement d'un export | MIT | victorcarreras.dev |
| `image_picker` | 1.2.4 | Choix de photos dans la galerie, sans permission | Apache-2.0 / BSD-3 | flutter.dev |
| `receive_sharing_intent` | 1.9.0 | « Partager vers DocuSafe » | Apache-2.0 | kasem.dev |
| `share_plus` | 13.3.1 | Feuille de partage du système | BSD-3 | fluttercommunity.dev |
| `pdf` | 3.13.1 | Création du PDF à partir des pages scannées | Apache-2.0 | nfet.net |
| `pdfrx` | 2.12.1 | Affichage des PDF, rendu de la première page pour la miniature. Télécharge PDFium depuis GitHub à la compilation (empreinte contrôlée par le paquet). Non exercé en session en ligne : voir P5. | MIT | espresso3389.jp |
| `image` | 4.13.0 (vérifié le 14/11/2026) | Miniatures : décodage, rotation EXIF, réduction, JPEG | MIT | taosengine.com |

### Rappels

| Paquet | Version | Rôle | Licence | Éditeur |
|---|---|---|---|---|
| `flutter_local_notifications` | 23.0.2 | Notifications locales programmées | BSD-3 | dexterx.dev |
| `timezone` | 0.11.2 | Heure locale correcte (changements d'heure) | BSD-2 | labs.dart.dev |
| `flutter_timezone` | 5.1.1 | Lecture du fuseau horaire du téléphone | Apache-2.0 | wolverinebeach.net |

### Divers

| Paquet | Version | Rôle | Licence | Éditeur |
|---|---|---|---|---|
| `package_info_plus` | 10.2.2 | Numéro de version dans « À propos » | BSD-3 | fluttercommunity.dev |
| `url_launcher` | 6.3.3 | Ouvrir l'adresse d'assistance (déjà requis par `pdfrx`) | BSD-3 | flutter.dev |

### Outils de développement (absents de l'application livrée)

| Paquet | Version | Rôle | Licence |
|---|---|---|---|
| `drift_dev` + `build_runner` | 2.35.3 / 2.17.1 | Génération du code de la base | MIT / BSD-3 |
| `flutter_lints` | 6.0.0 | Règles de qualité du code | BSD-3 |
| `mocktail` | 1.0.5 | Objets simulés pour les tests | MIT |
| `flutter_test`, `integration_test` | SDK | Tests | BSD-3 |
| `flutter_launcher_icons` | 0.14.4 | Génération des icônes Android et iOS | MIT |
| `flutter_native_splash` | 2.4.8 | Écran de démarrage natif | MIT |

**Bilan :** 27 paquets dans l'application, tous sous licence permissive (MIT, BSD, Apache-2.0), donc utilisables dans un produit commercial. Leur seule obligation est de reproduire les mentions de licence : Flutter le fait automatiquement dans l'écran « Licences » (Paramètres → À propos).

Composants natifs embarqués : SQLite (domaine public), SQLite3MultipleCiphers (MIT), PDFium (BSD-3 / Apache-2.0), Tink (Apache-2.0). Le scanner ML Kit est soumis aux conditions d'utilisation de Google ML Kit, gratuites pour un usage commercial ; elles seront relues en phase 6.

---

## 2. Paquets prévus après le MVP

| Paquet | Version actuelle | Rôle | Remarque |
|---|---|---|---|
| `google_mlkit_text_recognition` | 1.0.3 | OCR sur l'appareil | iOS 15 minimum. Sur iOS, un fichier de ressources doit être ajouté à la main dans Xcode : **à vérifier sur iOS**. |
| `in_app_purchase` | 3.3.1 | Achats intégrés (Premium) | Aucun paiement fictif d'ici là. Nécessitera la permission Internet. |
| Service de synchronisation | à choisir | Synchronisation facultative | Interface `SyncService` déjà prévue |

---

## 3. Écarts par rapport au cahier des charges

| Le cahier des charges suggère | Ce qui est retenu | Raison |
|---|---|---|
| SQLCipher | SQLite3MultipleCiphers, via le paquet `sqlite3` | `sqlcipher_flutter_libs` est en fin de vie depuis février 2026 (version marquée `+eol`). Le chiffrement est maintenant intégré à `sqlite3`. SQLite3MultipleCiphers n'embarque pas OpenSSL et suit de près les versions de SQLite. |
| ML Kit Document Scanner + VisionKit | `cunning_document_scanner` | Il utilise précisément ces deux technologies. `google_mlkit_document_scanner` ne fonctionne que sur Android, comme le signale le cahier des charges. |
| `flutter_lints` ou `very_good_analysis` | `flutter_lints` + règles ajoutées | Voir D16 dans [01-analyse.md](01-analyse.md) |

---

## 4. Paquets écartés

| Paquet | Raison |
|---|---|
| `google_mlkit_document_scanner` | Android uniquement |
| `flutter_doc_scanner` | Encore en version 0.0.x, moins mûr que le paquet retenu |
| `sqlcipher_flutter_libs`, `sqlite3_flutter_libs` | En fin de vie |
| `drift_flutter` | Simple raccourci d'ouverture de base, inutile ici ; il tire en plus les deux paquets en fin de vie |
| `biometric_storage` | Plus de mise à jour depuis février 2024. `flutter_secure_storage` offre désormais la même protection matérielle. |
| `image_cropper`, `crop_your_image` | Le recadrage est déjà fourni par le scanner |
| `shared_preferences` | Les rares réglages lus avant le déverrouillage vont dans le stockage sécurisé |
| `google_fonts` | Télécharge les polices sur Internet. Les polices du système suffisent. |
| `uuid` | Un identifiant aléatoire se génère en quelques lignes avec le générateur sécurisé de Dart |
| `permission_handler` | Chaque paquet demande déjà lui-même la permission dont il a besoin |
| `freezed`, `json_serializable`, `riverpod_generator` | Génération de code supplémentaire sans nécessité pour un modèle de cette taille |
| `very_good_analysis` | Voir D16 |

---

## 5. Points de vigilance

| Paquet | Constat | Mesure |
|---|---|---|
| `cryptography`, `cryptography_flutter` | Dernière version en novembre 2025 : paquets stables mais peu actifs. La partie Android utilise une configuration Gradle ancienne. `FlutterCryptography.enable()` est déprécié : le paquet s'active seul. | Chiffrement isolé derrière l'interface `CryptoEngine` (phase 3 : fait). Mesure de vitesse sur téléphone encore à faire (P4). **Plan B : `webcrypto`** (éditeur google.dev, mis à jour le 11/11/2026), sans Argon2id mais avec PBKDF2 natif. |
| `sqlite3` | Télécharge un binaire précompilé pendant la compilation (contrôlé par empreinte SHA-256). | **La première compilation exige une connexion Internet.** |
| `flutter_local_notifications` | Exige `compileSdk` 37 et l'option Gradle « desugaring ». | Configuration Android en phase 3. La plateforme Android 37 est déjà installée sur le PC. |
| `cunning_document_scanner` | Déclare ses propres règles de sauvegarde Android, qui entrent en conflit avec celles de DocuSafe. Écrit ses images dans un dossier externe privé. | Attribut `tools:replace` dans le manifeste. Purge du dossier après chaque scan. |
| `local_auth`, `flutter_secure_storage` | La fenêtre biométrique exige que `MainActivity` hérite de `FlutterFragmentActivity`. | Configuration Android en phase 3 |
| `receive_sharing_intent` | Sur iOS : Swift Package Manager obligatoire, `SceneDelegate`, extension de partage à créer dans Xcode. | Partie Android dans le MVP. Partie iOS reportée, comme l'autorise le cahier des charges. **À vérifier sur iOS.** |
| `pdfrx` | Embarque PDFium (quelques Mo par architecture). iOS 15 minimum. | Livraison en AAB : chaque téléphone ne télécharge que sa propre architecture. |
| Tous | Versions majeures récentes : beaucoup d'exemples trouvés en ligne sont périmés. | Lecture de la documentation de la version exacte avant d'écrire le code. |

---

## 6. Versions minimales qui en découlent

| Plateforme | Minimum | Imposé par |
|---|---|---|
| Android | **7.0 (API 24)** | Flutter 3.50, `flutter_secure_storage`, `local_auth`, `cunning_document_scanner`, `flutter_local_notifications` |
| iOS | **15.0** | Flutter 3.50, `pdfrx` |
| Flutter | 3.47 ou plus | `pdfrx` → Flutter 3.50 convient |
