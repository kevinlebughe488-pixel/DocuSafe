# App Store (iPhone)

L'iPhone vient après Google Play (cahier des charges §13). Le projet iOS est configuré (identifiant `com.docusafe.app`, iOS 15 minimum, textes des permissions) et la recette « Compilation iOS » vérifie qu'il compile.

## Ce qu'il faut (vous)

1. Un compte **Apple Developer Program** (99 dollars par an à la date de rédaction).
2. Pas besoin de Mac : la compilation signée peut se faire sur un Mac dans le cloud (Mac de GitHub, ou service Codemagic). Les certificats et profils de signature se créent depuis le site développeur d'Apple ; je préparerai la recette correspondante quand le compte existera.
3. Un iPhone pour les essais, avec l'application **TestFlight** (distribution de test d'Apple).

## Fiche

| Champ | Texte |
|---|---|
| Nom (30 caractères au plus) | DocuSafe – Coffre-fort privé |
| Sous-titre (30 caractères au plus) | Vos documents, protégés. |
| Mots-clés (100 caractères au plus) | coffre-fort,documents,chiffrement,papiers,identité,scanner,passeport,factures,échéances,diplômes |
| Catégorie | Productivité (secondaire : Utilitaires) |
| Description | Celle de Google Play ([play-store.md](play-store.md)), en remplaçant « empreinte ou visage » par « Face ID ou Touch ID » |
| Captures (iPhone 6,9 pouces, 1290 × 2796) | `captures/ios/`, même ordre que pour Google Play |
| Confidentialité (« App Privacy ») | **Données non collectées** |
| Politique de confidentialité | Même adresse que pour Google Play |

## Chiffrement

App Store Connect pose des questions sur le chiffrement (réglementation de l'export). DocuSafe utilise des algorithmes standard (AES-256-GCM, ChaCha20-Poly1305, Argon2id) uniquement pour protéger les données de l'utilisateur sur son appareil. La réponse exacte et l'éventuelle déclaration en France (ANSSI) sont **à vérifier** avant la publication : point juridique.

## Points « à vérifier sur iOS »

Code écrit selon la documentation mais jamais exécuté sur un iPhone :

| Sujet | Fichier |
|---|---|
| Trousseau limité à l'appareil, clé biométrique invalidée si Face ID change | `lib/core/security/keys/secure_store.dart` |
| Masquage de l'écran dans le sélecteur d'applications | `lib/core/widgets/privacy_shield.dart`, `lib/core/security/screen/screen_security.dart` |
| Notifications (délégué, autorisation) | `ios/Runner/AppDelegate.swift`, `lib/core/platform/notification_service.dart` |
| Scanner VisionKit | `lib/core/platform/scanner_service.dart` |
| Enregistrer une sauvegarde ou une archive (« Enregistrer dans Fichiers ») | `lib/core/platform/share_service.dart` |
| Textes des permissions | `ios/Runner/Info.plist` |
| Espace libre (non affiché sur iPhone pour l'instant) | `lib/core/platform/share_service.dart` |
