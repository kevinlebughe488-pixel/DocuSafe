# Rapport de couverture des tests

Produit le 15/11/2026 par `tool/coverage_report.py` à partir de `flutter test --coverage --exclude-tags screenshots`.
La couverture est la part des lignes de code exécutées au moins une fois pendant les tests automatiques. Le code généré est exclu.

**Couverture totale : 79 %** (5634 lignes sur 7172).

| Partie | Lignes couvertes | Couverture |
|---|---|---|
| Sécurité : chiffrement, clés, code, verrouillage (`lib/core/security/`) | 698 / 814 | 86 % |
| Base de données (`lib/core/database/`) | 300 / 399 | 75 % |
| Documents : ajout, lecture, export, recherche (`lib/core/documents/`) | 423 / 469 | 90 % |
| Sauvegarde et restauration (`lib/core/backup/`) | 99 / 107 | 93 % |
| Échéances et rappels (`lib/core/reminders/`) | 88 / 90 | 98 % |
| Fichiers du coffre (`lib/core/storage/`) | 46 / 52 | 88 % |
| Services du téléphone (simulés dans les tests) (`lib/core/platform/`) | 78 / 241 | 32 % |
| Autres éléments du cœur (utilitaires, composants) (`lib/core/`) | 694 / 777 | 89 % |
| Écrans (`lib/features/`) | 2933 / 3934 | 75 % |
| Application : thème, navigation (`lib/app/`) | 275 / 289 | 95 % |

## Fichiers les moins couverts

Fichiers de plus de 30 lignes, couverture la plus faible d'abord. Les services du téléphone (scanner, sélecteurs, notifications, partage) ne peuvent s'exécuter que sur un vrai téléphone : ils sont remplacés par des versions simulées dans les tests et vérifiés par les essais sur téléphone.

| Fichier | Couverture |
|---|---|
| `lib/core/database/tables.dart` | 7 % (5/73) |
| `lib/features/auth/presentation/reauth/reauth_sheet.dart` | 8 % (4/53) |
| `lib/core/platform/notification_service.dart` | 25 % (13/51) |
| `lib/core/platform/file_picker_service.dart` | 29 % (12/42) |
| `lib/features/settings/presentation/security_settings_screen.dart` | 34 % (42/124) |
| `lib/core/platform/thumbnail_service.dart` | 34 % (18/53) |
| `lib/core/platform/share_service.dart` | 35 % (14/40) |
| `lib/core/platform/share_intake_service.dart` | 39 % (12/31) |
| `lib/features/documents/presentation/list/documents_view_model.dart` | 42 % (14/33) |
| `lib/features/auth/presentation/setup/setup_screen.dart` | 47 % (25/53) |
| `lib/features/documents/presentation/list/documents_screen.dart` | 49 % (76/156) |
| `lib/features/settings/presentation/security_settings_view_model.dart` | 50 % (30/60) |
| `lib/features/auth/presentation/unlock/unlock_view_model.dart` | 51 % (31/61) |
| `lib/features/documents/presentation/viewer/document_viewer_screen.dart` | 54 % (49/91) |
| `lib/features/reminders/presentation/document_reminders_screen.dart` | 61 % (63/104) |
