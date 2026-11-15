# Tests et analyse des risques (phase 5)

État au 15/11/2026. Ce document répond au §10 du cahier des charges (tests et validation) et met à jour les risques de [01-analyse.md](01-analyse.md).

## 1. Comment les tests sont lancés

| Niveau | Outil | Où |
|---|---|---|
| Tests unitaires et tests d'écrans (« tests de widgets ») | `flutter test` | Session en ligne, et GitHub à chaque envoi de code |
| Analyse statique (recherche d'erreurs sans lancer le code) | `flutter analyze` | Idem |
| Test sur téléphone simulé | `tool/smoke_test.py` sur un émulateur Android (GitHub) | À chaque envoi de code, après la compilation de l'APK |
| Captures d'écran de référence | `test/screenshots/` | À la demande |

Le test sur téléphone simulé installe la vraie application (version « aperçu »), crée un coffre, le verrouille, le rouvre avec le code, arrête puis relance l'application et rouvre encore le coffre. C'est le seul test qui exerce le vrai stockage sécurisé d'Android et la vraie base chiffrée. Il tourne sur un **petit écran** (320 × 640 points) pour représenter un téléphone d'entrée de gamme.

Les tests d'intégration du paquet `integration_test` (`integration_test/app_test.dart`) font tourner la vraie application sur un émulateur Android dans la recette « Tests d'intégration » : création du coffre, mauvais code refusé, réouverture, profil, aide. Le scanner, les sélecteurs du système et les notifications restent à vérifier sur un vrai téléphone (plan d'essais).

Couverture des tests : [rapport-couverture.md](rapport-couverture.md) (79 % des lignes au 15/11/2026), recalculée à chaque compilation de l'aperçu.

## 2. Correspondance avec le cahier des charges (§10)

### Tests unitaires

| Exigence | Tests |
|---|---|
| Création de documents | `test/core/documents/documents_test.dart` (vérification, ingestion, miniature) |
| Modification | `documents_test.dart` (dépôt : fiche, modification), `test/core/database/app_database_test.dart` |
| Suppression | `documents_test.dart` (suppression : base et fichiers) |
| Classification | `app_database_test.dart` (catégories, suppression d'une catégorie), `test/features/import_flow_test.dart` |
| Recherche | `test/core/documents/scan_and_search_test.dart`, `app_database_test.dart` |
| Gestion des dates | `test/core/formats_test.dart`, `test/core/reminders/reminder_service_test.dart` |
| Chiffrement et déchiffrement | `test/core/security/file_cipher_test.dart` |
| Gestion des clés | `test/core/security/vault_service_test.dart`, `recovery_key_test.dart`, `pin_policy_test.dart` |

### Tests d'intégration

| Exigence | Tests | Reste à faire sur téléphone |
|---|---|---|
| Scanner vers stockage | `test/features/scan_search_flow_test.dart` (scanner simulé, vraies images, vrai PDF chiffré) | Écran du scanner du système (P5) |
| Importation vers stockage | `test/features/import_flow_test.dart` | Sélecteur du système |
| OCR vers index de recherche | Hors MVP (voir 01-analyse.md §3) | — |
| Notifications | `reminder_service_test.dart`, `test/features/deadlines_flow_test.dart` (service simulé) | Affichage réel, fabricants qui coupent les tâches de fond (R6) |
| Exportation | `test/core/documents/export_test.dart`, `test/features/share_export_flow_test.dart` | Feuille de partage, « Enregistrer sous » (P6) |
| Gestion de la base de données | `app_database_test.dart`, `vault_service_test.dart` (base chiffrée sur disque), téléphone simulé | — |
| Sauvegarde et restauration | `test/core/backup/backup_test.dart`, `test/features/backup_restore_flow_test.dart`, `storage_backup_flow_test.dart` | Restauration sur un deuxième téléphone (P6) |

### Tests de sécurité

| Exigence | Tests |
|---|---|
| Accès sans authentification | `test/features/access_control_test.dart` : sans coffre ou coffre verrouillé, aucune adresse protégée ne s'affiche |
| Mauvaise saisie du PIN | `vault_service_test.dart` (refus, compteur, attentes de 30 s à 60 min) |
| Verrouillage automatique | `access_control_test.dart` : inactivité, arrière-plan, tolérance de cinq minutes pour les fenêtres ouvertes par DocSafe ; `session_providers_test.dart` : après un verrouillage, la base est bien celle de la nouvelle session ; `deadlines_flow_test.dart` : les rappels sont reprogrammés à la réouverture ; téléphone simulé : verrouillage, réouverture, relance |
| Vérification du chiffrement des fichiers | `file_cipher_test.dart`, `documents_test.dart` (aucun octet en clair sur le disque), `vault_service_test.dart` (base illisible sans la clé), `backup_test.dart` (rien en clair dans une sauvegarde) |
| Vérification des journaux | `test/core/logging_test.dart` : aucun `print`, codes fixes seulement, une erreur est journalisée par son type et jamais par son message |
| Gestion des fichiers temporaires | `documents_test.dart`, `export_test.dart`, `scan_search_flow_test.dart` (abandon d'un scan), `storage_backup_flow_test.dart` (nettoyage), `share_export_flow_test.dart` (purge au verrouillage) |
| Corruption de fichiers | `file_cipher_test.dart` (octet modifié, fichier tronqué, blocs échangés), `documents_test.dart` (fichier altéré ou remplacé), `export_test.dart`, `backup_test.dart` (sauvegarde abîmée) |
| Interruption d'une opération | `test/core/security/consistency_test.dart` : au déverrouillage suivant, fichiers provisoires et fichiers orphelins supprimés, documents intacts ; `vault_service_test.dart` (préparer sans valider : rien n'est écrit) |

### Tests d'interface

| Exigence | Tests |
|---|---|
| Navigation complète | `access_control_test.dart`, les tests de parcours de `test/features/`, captures d'écran, `integration_test/app_test.dart` (vraie application sur émulateur) |
| Grande taille de police | `large_text_test.dart` : écrans principaux à 200 % |
| « Partager vers DocSafe » | `share_intake_flow_test.dart` (coffre verrouillé puis ouvert) |
| Code oublié, lecture, modification, textes légaux, aide | `more_screens_test.dart`, `help_and_details_test.dart` |
| Onboarding | `test/features/vault_flow_test.dart`, téléphone simulé |
| Ajout d'un document | `import_flow_test.dart` |
| Recherche | `scan_search_flow_test.dart` |
| Scanner | `scan_search_flow_test.dart` |
| Modification | `import_flow_test.dart`, `deadlines_flow_test.dart` |
| Suppression | `import_flow_test.dart` |
| Exportation | `share_export_flow_test.dart` |
| Petit écran | `vault_flow_test.dart` (320 × 640 points), téléphone simulé |

## 3. Défauts trouvés et corrigés en phase 5

| Défaut | Gravité | Trouvé par | Correction |
|---|---|---|---|
| Après un verrouillage puis un déverrouillage, l'application utilisait encore la base fermée de la première session | Bloquant | Relecture, puis test de régression | Les fournisseurs de session et de base sont recalculés à chaque session |
| Sur un petit écran, le bouton « Continuer » du code passait sous le clavier : le toucher ajoutait un chiffre | Bloquant sur les petits téléphones | Téléphone simulé | Clavier à taille adaptable, disposition compacte |
| **Le coffre ne pouvait pas être créé sur Android** : le paquet `cryptography_flutter` remplaçait le calcul HMAC (utilisé pour dériver les clés) par du code natif qui échouait | Bloquant | Essai du développeur sur Appetize, cause trouvée par le journal du téléphone simulé | Paquet retiré ; chiffrement entièrement en Dart pur, identique dans les tests et sur le téléphone |
| Une erreur imprévue pendant la création du coffre laissait la roue tourner sans fin | Majeur | Même essai | Toute erreur est affichée ; la vérification de la biométrie ne peut plus bloquer l'entrée |
| Le contrôle de cohérence décrit dans la documentation n'était pas écrit | Mineur | Relecture | Fichiers orphelins supprimés au déverrouillage |
| À la réouverture du coffre, la reprogrammation des rappels lisait encore la base fermée de la session précédente (rappels non reprogrammés) | Majeur | Journal du téléphone simulé, puis test de régression | Le service des rappels est construit sur la session qui vient de s'ouvrir |
| **La version publiable contenait la permission Internet** (et l'état du réseau), ajoutée par un paquet pour ses statistiques d'usage (scanner ML Kit) | Bloquant (règle D8, fiche « aucune donnée collectée ») | Contrôle automatique `tool/check_apk.py` (phase 6) | Permissions retirées explicitement dans le manifeste ; contrôle rendu vraiment bloquant |
| **« Code oublié » ne laissait pas choisir de nouveau code** : après la clé de récupération, l'application allait directement à l'accueil, avec l'ancien code (oublié) | Majeur | Nouveau test de l'écran « Code oublié » | L'écran reste affiché jusqu'au choix du nouveau code |
| Écran du code et en-tête d'étape débordaient à la taille de police maximale (200 %) | Majeur (accessibilité) | Nouveau test à 200 % | Écran du code défilant en très grande police, libellé d'étape raccourci au besoin |
| Quitter l'écran de restauration sans restaurer provoquait une erreur interne | Mineur | Captures d'écran | Corrigé |
| La barre de répartition de l'écran Stockage ne s'affichait pas | Mineur | Captures d'écran | Corrigé |

## 4. Analyse des risques, mise à jour

| N° | Risque | État au 15/11/2026 |
|---|---|---|
| R1 | Flutter n'est pas installé sur le PC | Toujours bloqué par le virus (P1). Contourné : session en ligne et compilation par GitHub. |
| R2 | iOS ne peut pas être testé | Réduit : l'application iPhone **compile** sur un Mac de GitHub (15/11/2026). Elle n'a pas encore tourné sur un iPhone : le code propre à iOS reste marqué « à vérifier sur iOS » (docs/publication/app-store.md). |
| R3 | `cryptography_flutter` évolue lentement | **Réalisé puis traité** : son code natif faisait échouer la création du coffre sur Android. Paquet retiré le 15/11/2026, chiffrement en Dart pur derrière `CryptoEngine`. |
| R4 | Téléphones lents | Mesures dans la session en ligne (machine rapide) : code vérifié en 0,35 s ; fichier de 20 Mo chiffré en 3 s. Sur un téléphone d'entrée de gamme, compter 4 à 8 fois plus. **À mesurer en phase 6.** Si c'est trop lent : chiffrement natif dans l'isolate (plan B de 06-dependances.md §5). |
| R5 | Scanner ML Kit indisponible | Non vérifiable hors d'un téléphone (P5). |
| R6 | Fabricants qui coupent les tâches de fond | Inchangé : l'onglet Échéances reste la référence, rappels replanifiés à chaque déverrouillage. |
| R7 | Code **et** clé de récupération perdus | Assumé. Depuis D6 révisée, la clé est proposée par un rappel : un utilisateur peut l'ignorer. La sauvegarde exige que la clé ait été notée, ce qui pousse à le faire. |
| R8 | Fichiers en clair pendant un court instant | Couvert : `secure_tmp/` purgé après chaque opération, au verrouillage et au démarrage ; tests dédiés. |
| R9 | Paquets récents | Versions figées ; chaque paquet ajouté a été vérifié sur sa version exacte. |
| R10 | Nom « DocSafe » | À vérifier avant publication (conseil juridique). |
| R11 | Exigences des magasins | Phase 6. |
| **R12** | L'application n'a jamais tourné sur un vrai téléphone | Réduit par le téléphone simulé de GitHub (création, verrouillage, réouverture). Restent : scanner, lecture des PDF, partage, notifications, biométrie (P4, P5, P6). |
| **R13** | Une sauvegarde ne s'ouvre qu'avec la clé de récupération en vigueur quand elle a été faite | Indiqué à l'écran. Après un changement de clé, il faut refaire une sauvegarde. |
| **R14** | Réduction du code Android à la compilation (« R8 ») : un paquet peut perdre une classe dont il a besoin | Le démarrage montre un avertissement sans conséquence pour ML Kit. À surveiller pour les notifications programmées et le scanner lors des essais réels. |
| **R15** | Petits écrans et grandes polices | Clavier du code corrigé et testé à 320 × 640. Les autres écrans défilent. À revoir avec la taille de police maximale du système en phase 6. |
| **R16** | La version « aperçu » ne bloque pas les captures d'écran et écrit un journal technique | Volontaire, limité à cette version (identifiant et clé de signature distincts). La version publiée n'est pas concernée. |

## 5. Optimisation

| Sujet | Constat | Décision |
|---|---|---|
| Taille de l'APK | 97 Mo : il contient le code pour trois familles de processeurs | Normal pour un APK de test « universel ». Le format de publication (AAB) ne livre que la partie utile à chaque téléphone, environ un tiers. Les téléphones 32 bits restent pris en charge : ils sont courants en entrée de gamme. |
| Chiffrement des fichiers | Environ 7 Mo par seconde dans la session en ligne, en Dart pur, dans un isolate (il l'était déjà : le code natif ne s'applique pas dans un isolate) | Suffisant pour des documents de quelques Mo. À mesurer sur téléphone (R4). |
| Vérification du code | 0,35 s (Argon2id, 19 Mo de mémoire, 2 passes), dans un isolate | Conforme aux recommandations OWASP. À mesurer sur téléphone (R4). |
| Export complet et sauvegarde | Étaient chargés en mémoire, d'où une limite de 200 Mo | Copie par petits morceaux sur Android : limite levée. |
| Écran du code | Dépassait sur petit écran | Taille des touches calculée selon la hauteur disponible. |
| Textes | Un texte d'accueil obsolète restait dans le fichier des textes | Retiré. |
