# Conformité au cahier des charges

État au 15/11/2026. Pour chaque exigence : **Fait**, **Fait, à vérifier sur téléphone** (programmé et testé automatiquement, mais seul un vrai téléphone peut le confirmer), **Plus tard** (le cahier des charges autorise à le reporter) ou **Vous** (dépend d'un compte ou d'une décision du développeur).

## Fonctions (§3)

| § | Exigence | État |
|---|---|---|
| 3.1 | Accueil, création du coffre, code PIN, biométrie facultative, confidentialité, sans compte ni Internet, récupération expliquée | Fait |
| 3.2 | Tableau de bord : nom, nombre de documents, catégories, récents, favoris, échéances, scanner, importation, recherche | Fait |
| 3.2 | Tableau de bord personnalisable | Plus tard (« évolutions futures ») |
| 3.3 | Scanner : ML Kit (Android), VisionKit (iPhone), contours, perspective, multipage, aperçu, réorganisation, PDF, repli manuel | Fait, à vérifier sur téléphone |
| 3.4 | Importation : fichiers, galerie, PDF, JPEG, PNG, vérification et chiffrement | Fait |
| 3.4 | « Partager vers DocSafe » sur Android | Fait, à vérifier sur téléphone |
| 3.4 | Extension de partage iPhone | Plus tard (autorisé) |
| 3.5 | Sept catégories initiales, ajouter, modifier, supprimer, icône, couleur, déplacer ; documents gardés si la catégorie est supprimée | Fait |
| 3.5 | Sous-catégories | Plus tard (« évolution ultérieure ») |
| 3.6 | Fiche complète (dont date de modification, empreinte d'intégrité) ; consulter, renommer, modifier, tags, favori, partager, exporter, supprimer avec confirmation | Fait |
| 3.7 | Biométrie, PIN, verrouillage automatique, nouvelle authentification ; AES-256-GCM, clés dans le stockage sécurisé, intégrité SHA-256 ; aucune sauvegarde non maîtrisée (Android), captures et aperçu masqués, journaux sans données, fichiers temporaires gérés | Fait |
| 3.7 | Exclusion de la sauvegarde iCloud, masquage de l'aperçu (iPhone) | Fait, à vérifier sur iPhone |
| 3.7 | Accélération native par `cryptography_flutter` (« par exemple ») | Écart assumé : retiré, son code natif empêchait de créer le coffre sur Android ; chiffrement en Dart pur |
| 3.8 | Recherche par nom, catégorie, date, mot-clé, tag, hors ligne | Fait |
| 3.8, 3.9 | Recherche dans le texte, reconnaissance de texte (OCR), proposition de catégorie | Plus tard (§7 : « après validation du MVP ») |
| 3.10 | Échéances, rappels 90/30/7/0 jours, modifiables, désactivables, notifications locales, reprogrammés après redémarrage | Fait, à vérifier sur téléphone |
| 3.11 | Favoris, récents (consultés et ajoutés) | Fait |
| 3.12 | Export PDF et image, feuille de partage, avertissement, fichiers temporaires supprimés | Fait, à vérifier sur téléphone |
| 3.13 | Profil local, sécurité, biométrie, code, délai de verrouillage, notifications, stockage, export des données, sauvegarde et synchronisation, confidentialité, conditions, à propos, assistance | Fait (l'adresse de contact de l'assistance : **Vous**) |

## Architecture, interface, exigences non fonctionnelles (§4 à §6)

| § | Exigence | État |
|---|---|---|
| 4 | Flutter, couches, modèle de données, hors ligne, synchronisation préparée sans bouton factice | Fait |
| 5.3 | Les 21 écrans demandés | Fait |
| 6.1 | Opérations lourdes dans des isolates, documents volumineux | Fait ; fluidité sur téléphone d'entrée de gamme : à mesurer |
| 6.2 | Erreurs de stockage, fichiers corrompus, transactions, interruptions | Fait |
| 6.3 | Taille de police du système (testée à 200 %), lecteurs d'écran, contrastes, zones tactiles | Fait ; TalkBack et VoiceOver : à vérifier sur téléphone |
| 6.4 | Android et iPhone, tailles d'écran, exigences des magasins | Fait (Android 7 et plus, iOS 15 et plus, Android ciblé 36) |

## MVP, modèle économique, sécurité (§7 à §9)

| § | Exigence | État |
|---|---|---|
| 7 | Les 15 fonctions obligatoires | Fait |
| 8 | Architecture Freemium prête (`EntitlementService`), aucune fonction Premium simulée | Fait |
| 9 | Analyse des risques, flux de données, permissions justifiées, suppression sécurisée, limites documentées ; politique de confidentialité, conditions, formulaire « Sécurité des données », déclarations App Store | Fait (relecture juridique : **Vous**) |

## Tests (§10)

Matrice détaillée : [08-tests-et-risques.md](08-tests-et-risques.md). Tests unitaires, tests d'écrans, tests de sécurité : faits (108 tests). Tests d'intégration : `integration_test/`, exécutés sur un émulateur Android par la recette « Tests d'intégration » (réussis le 15/11/2026). Couverture : [rapport-couverture.md](rapport-couverture.md).

## Critères d'acceptation (§11)

| N° | Critère | État |
|---|---|---|
| 1 | Compile, `flutter analyze` sans erreur | Fait |
| 2 | Se lance sur émulateur et sur téléphone réel | Émulateur : fait ; téléphone réel : **Vous** |
| 3 | APK et AAB de version | Fait (signature de publication : **Vous**) |
| 4 | Créer un coffre | Fait (émulateur) |
| 5 | Scanner | Fait, à vérifier sur téléphone |
| 6 | Importer un PDF | Fait |
| 7 | Classer | Fait |
| 8 | Consulter hors ligne | Fait (images) ; PDF : à vérifier sur téléphone |
| 9 | Fichiers chiffrés | Fait |
| 10 | L'authentification protège | Fait |
| 11 | Retrouver un document | Fait |
| 12 | Rappels locaux | Fait, à vérifier sur téléphone |
| 13 | Export | Fait, à vérifier sur téléphone |
| 14 | Erreurs gérées | Fait |
| 15 | Tests critiques | Fait |
| 16 | Aucun blocage critique connu | Fait |
| 17 | Interface cohérente Android et iPhone | Fait |
| 18 | Projet iOS prêt à compiler | Fait (compilé sur un Mac de GitHub) |

## Livrables (§12)

Tous fournis, sauf ceux qui demandent un compte : build signé pour Google Play (clé d'envoi : **Vous**) et build TestFlight (compte Apple : **Vous**). Voir [publication/README.md](publication/README.md).
