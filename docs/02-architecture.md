# Architecture de DocSafe

Document rédigé le 13/11/2026 (phase 1). Il sera mis à jour à chaque phase.

---

## 1. Vue d'ensemble

L'application suit le modèle **MVVM** (Model – View – ViewModel) demandé par le cahier des charges, découpé en modules appelés *features*.

```
┌──────────────────────────────────────────────────────────────────┐
│  PRÉSENTATION    Écrans (widgets)  ◄──►  ViewModels (Riverpod)   │
├──────────────────────────────────────────────────────────────────┤
│  DOMAINE         Entités · Cas d'utilisation · Interfaces        │
├──────────────────────────────────────────────────────────────────┤
│  DONNÉES         Repositories · Base drift · Fichiers chiffrés   │
├─────────────────────────────────┬────────────────────────────────┤
│  SÉCURITÉ                       │  SERVICES DE LA PLATEFORME     │
│  chiffrement, clés, PIN,        │  scanner, import, partage,     │
│  biométrie, verrouillage        │  notifications, OCR (plus tard)│
└─────────────────────────────────┴────────────────────────────────┘
```

En une phrase : un **écran** affiche un état et transmet les actions de l'utilisateur à son **ViewModel** ; le ViewModel appelle le **domaine** ; le domaine s'appuie sur des **interfaces** ; les couches du bas fournissent les implémentations réelles.

### Règles de dépendance

Ces règles gardent le code testable et empêchent les mélanges :

1. Un écran ne parle qu'à son ViewModel. Il n'appelle jamais la base de données, un fichier ou un paquet natif.
2. Le **domaine est du Dart pur** : aucun import de Flutter ni d'un paquet de plateforme. On peut donc le tester sans téléphone.
3. Chaque paquet externe est utilisé **à un seul endroit**, derrière une interface. Changer de paquet (par exemple de scanner) ne touche qu'un fichier.
4. Un module n'importe jamais les dossiers `data/` ou `presentation/` d'un autre module. Ce qui est partagé va dans `core/`.
5. Rien de ce qui est déchiffré n'existe tant que le coffre est verrouillé (voir §6).

### Pas de complexité inutile

Le cahier des charges demande de ne pas créer une architecture inutilement complexe. Règle retenue : **un cas d'utilisation n'existe que s'il coordonne plusieurs services.** Renommer un document ou le mettre en favori passe directement du ViewModel au repository.

Cas d'utilisation prévus :

| Cas d'utilisation | Ce qu'il coordonne |
|---|---|
| `SetupVault` | Création des clés, enregistrement du PIN, clé de récupération, création de la base, catégories initiales |
| `UnlockVault` | Vérification du PIN (ou biométrie, ou clé de récupération), ouverture de la base |
| `LockVault` | Fermeture de la base, effacement des clés en mémoire, purge des fichiers temporaires |
| `ChangePin`, `EnableBiometrics`, `RegenerateRecoveryKey`, `WipeVault` | Opérations sur les clés |
| `IngestDocument` | Validation → (création du PDF) → empreinte → chiffrement → miniature → base → nettoyage. **Commun au scanner, à l'importation et au partage entrant.** |
| `OpenDocument` | Déchiffrement, contrôle d'intégrité, mise à jour de « consulté récemment » |
| `DeleteDocument` | Base + fichier + miniature + rappels |
| `ShareDocument`, `ExportDocument` | Nouvelle authentification, avertissement, fichier temporaire, nettoyage |
| `DeleteCategory` | Déplacement des documents puis suppression |
| `SyncReminders` | Calcul des rappels à partir des dates d'expiration, programmation des notifications |

---

## 2. Structure des dossiers

```
lib/
  main.dart                     Point d'entrée
  app/
    app.dart                    MaterialApp + routeur
    startup/                    Écran de démarrage (splash), initialisation
    router/                     Routes go_router et redirections (onboarding, verrouillage)
    theme/                      Thème Material 3, couleurs, typographie (clair et sombre)
    l10n/                       Textes de l'application (français)
    config/                     Constantes (limites de taille, délais…)
  core/
    security/
      crypto/                   CryptoEngine : AES-GCM, dérivation de clés, format de fichier chiffré
      keys/                     Gestion des clés du coffre, clé de récupération
      auth/                     PIN (tentatives, délais), biométrie
      lock/                     État du coffre, verrouillage automatique
      screen/                   Protection de l'écran (captures, aperçu des applications récentes)
    database/                   Base drift : tables, requêtes, migrations, index de recherche
    storage/                    Stockage des fichiers chiffrés, fichiers temporaires
    platform/                   Scanner, import, partage, notifications, OCR (interface seule)
    entitlements/               Gratuit / Premium (interface seule dans le MVP)
    sync/                       SyncService (interface seule dans le MVP)
    errors/                     Types d'erreurs
    utils/                      Dates, formats, journal technique sans données sensibles
    widgets/                    Composants d'interface réutilisables, états vides, écrans d'erreur
  features/
    onboarding/
    auth/
    dashboard/
    documents/
    scanner/
    categories/
    search/
    reminders/
    settings/
        chacune contient :  presentation/   domain/   data/
android/                        Projet Android (manifeste, Gradle, MainActivity)
ios/                            Projet iOS (Info.plist, configuration) — à vérifier sur iOS
test/                           Tests unitaires et tests de widgets
integration_test/               Tests sur émulateur et téléphone
docs/                           Documentation
```

Conventions : noms de fichiers en `snake_case` ; suffixes `_screen.dart`, `_view_model.dart`, `_repository.dart` ; **identifiants en anglais, commentaires et documentation en français.**

---

## 3. Modules et écrans

Les 21 écrans du cahier des charges (§5.3) sont répartis ainsi :

| Module | Responsabilité | Écrans |
|---|---|---|
| `app/startup` | Démarrage, choix de la première page | 1. Splash |
| `onboarding` | Présentation de DocSafe, stockage local, confidentialité | 2. Onboarding |
| `auth` | Création du coffre, déverrouillage, récupération | 3. Configuration du coffre-fort · 4. Authentification |
| `dashboard` | Vue d'ensemble | 5. Tableau de bord |
| `documents` | Liste, fiche, lecture, modification, importation, favoris, récents, suppression, partage, export | 6. Liste · 7. Détail · 10. Importation · 13. Favoris · 14. Récents · 20. Confirmation de suppression |
| `scanner` | Lancement du scanner, tri des pages, création du PDF | 8. Scanner · 9. Prévisualisation du scan |
| `categories` | Catégories, icônes, couleurs | 11. Création et modification de catégories |
| `search` | Recherche et filtres | 12. Recherche |
| `reminders` | Échéances et rappels | 15. Échéances · 16. Gestion des rappels |
| `settings` | Tous les réglages | 17. Sécurité · 18. Paramètres généraux · 19. Stockage |
| `core/widgets` | Composants communs | 21. Erreurs et états vides |

Le tableau de bord est construit comme une **liste de sections indépendantes** (compteur, catégories, récents, favoris, échéances). Les rendre réorganisables plus tard ne demandera pas de réécriture.

---

## 4. Gestion d'état (Riverpod)

- Chaque écran a un ViewModel : un `Notifier` ou `AsyncNotifier` Riverpod qui expose **un état immuable** et des méthodes (les actions de l'utilisateur).
- Les services et repositories sont fournis par des *providers*. Dans les tests, on les remplace par des versions simulées.
- Les listes viennent de **requêtes observées** de drift : quand une donnée change, les écrans concernés se mettent à jour seuls (tableau de bord, compteurs, listes).
- Pas de génération de code pour Riverpod : une seule étape de génération suffit (celle de drift).

---

## 5. Navigation (go_router)

### Barre de navigation inférieure

Cinq destinations, comme demandé : **Accueil · Documents · Scanner · Échéances · Paramètres**. Le Scanner est au centre et mis en valeur.

### Routes

| Route | Écran |
|---|---|
| `/` | Splash : décide de la suite |
| `/onboarding` | Onboarding |
| `/setup` | Configuration du coffre (PIN, clé de récupération, biométrie) |
| `/lock` | Déverrouillage · `/lock/recovery` : clé de récupération |
| `/home` | Tableau de bord |
| `/documents` | Liste (filtres par catégorie, tri) |
| `/documents/favorites`, `/documents/recent` | Favoris, Récents |
| `/documents/import` | Importation |
| `/documents/:id` | Fiche du document |
| `/documents/:id/view` | Lecture (PDF ou image) |
| `/documents/:id/edit` | Modification des informations |
| `/documents/:id/delete` | Confirmation de suppression |
| `/scan`, `/scan/preview` | Scanner, prévisualisation |
| `/search` | Recherche |
| `/categories`, `/categories/new`, `/categories/:id` | Catégories |
| `/deadlines` | Échéances · `/deadlines/:documentId/reminders` : rappels d'un document |
| `/settings` | Paramètres généraux |
| `/settings/security`, `/settings/storage`, `/settings/notifications`, `/settings/export`, `/settings/backup`, `/settings/privacy`, `/settings/terms`, `/settings/about` | Sous-écrans |

### Redirections automatiques

Le routeur observe l'état du coffre et applique ces règles **avant d'afficher quoi que ce soit** :

| État du coffre | Conséquence |
|---|---|
| Aucun coffre | Seules `/onboarding` et `/setup` sont accessibles |
| Verrouillé | Toute route est redirigée vers `/lock` ; l'adresse demandée est mémorisée et rouverte après le déverrouillage |
| Déverrouillé | Navigation libre |

---

## 6. Cycle de vie du coffre

```
                 création                     PIN / biométrie / clé de récupération
  AUCUN COFFRE ───────────► DÉVERROUILLÉ ◄──────────────────────────────── VERROUILLÉ
        ▲                        │                                             ▲
        │                        └──── arrière-plan · inactivité · bouton ─────┘
        └───────────── effacement du coffre (paramètres) ─────────────
```

| État | Clé du coffre en mémoire | Base de données | Écrans accessibles |
|---|---|---|---|
| Aucun coffre | Non | N'existe pas | Onboarding, configuration |
| Verrouillé | **Non** | **Fermée** | Déverrouillage uniquement |
| Déverrouillé | Oui | Ouverte | Tous |

Point important : la protection ne repose pas sur le fait de cacher des écrans. Quand le coffre est verrouillé, **la clé n'est plus en mémoire et la base est fermée**. Même un défaut d'affichage ne pourrait rien montrer.

---

## 7. Ajout d'un document : un seul chemin

Le scanner, l'importation et le partage depuis une autre application aboutissent tous au même traitement (`IngestDocument`) :

```
 Scanner ──┐
 Fichiers ─┼─► 1. Copie dans le dossier temporaire privé
 Galerie ──┤   2. Validation : type réel du fichier, taille, lisibilité, doublon
 Partage ──┘   3. Scanner : assemblage des pages en un PDF
               4. Formulaire : nom, catégorie, date d'expiration, tags
               5. Chiffrement par blocs + calcul de l'empreinte SHA-256
               6. Relecture de contrôle du fichier chiffré
               7. Miniature chiffrée
               8. Enregistrement en base (une seule transaction)
               9. Suppression des fichiers temporaires en clair
```

Si l'application est interrompue (appel, batterie vide, fermeture forcée) : le fichier chiffré est d'abord écrit sous un nom provisoire, puis renommé en une seule opération. Au prochain déverrouillage, un contrôle supprime les fichiers provisoires et les fichiers qui ne correspondent à aucune ligne de la base. **Un document n'apparaît donc jamais à moitié enregistré.**

---

## 8. Traitements lourds

Exigence : rien de lourd sur le fil d'exécution de l'interface.

| Traitement | Où il s'exécute |
|---|---|
| Vérification du PIN (Argon2id) | Isolate |
| Chiffrement, déchiffrement, empreinte SHA-256 | Isolate, par blocs de 1 Mo (mémoire maîtrisée, progression affichable) |
| Création du PDF à partir des pages | Isolate |
| Création des miniatures | Décodage natif réduit + isolate |
| Base de données | Isolate dédié de drift |
| OCR (après le MVP) | Natif (ML Kit), asynchrone |

Pour les téléphones d'entrée de gamme : listes chargées progressivement, miniatures déchiffrées seulement quand elles deviennent visibles et gardées dans un petit cache en mémoire, images affichées à la taille de l'écran, jamais en pleine résolution.

---

## 9. Gestion des erreurs

- Les couches basses lèvent des erreurs **typées** (`AppException`) : stockage, chiffrement ou intégrité, authentification, validation, plateforme, annulation par l'utilisateur.
- Le ViewModel les transforme en état d'écran. L'écran affiche un message en français clair et, si possible, une action (« Réessayer », « Libérer de l'espace »).
- Aucune erreur n'est avalée en silence (règles d'analyse activées pour cela).
- Les erreurs imprévues sont interceptées globalement, enregistrées **sans aucune donnée sensible**, et un écran d'erreur générique s'affiche.

---

## 10. Code spécifique à chaque plateforme

Tout ce qui dépend d'une plateforme est isolé ici. Ce qui n'aura pas pu être testé portera la mention **« à vérifier sur iOS »** dans le code et dans la documentation.

| Sujet | Android | iOS (à vérifier sur iOS) |
|---|---|---|
| Activité principale | `MainActivity` hérite de `FlutterFragmentActivity` (obligatoire pour la biométrie) | — |
| Captures d'écran et aperçu des applications récentes | Canal `docusafe/screen_security` → `FLAG_SECURE` | Écran de masquage quand l'application devient inactive |
| Sauvegardes du système | `allowBackup="false"` + règles d'extraction de données | Dossier du coffre exclu de la sauvegarde iCloud |
| Permissions | `AndroidManifest.xml` | `Info.plist` (caméra, Face ID, photothèque) |
| Partage entrant | Filtres d'intention dans le manifeste | Extension de partage (reportée après le MVP) |
| Rappels après redémarrage | Récepteur de démarrage du paquet de notifications | Géré par iOS |
| Réinstallation | Les clés disparaissent avec l'application | Le trousseau survit à une désinstallation : nettoyage à prévoir au premier lancement |
| Build | `compileSdk` 37, `minSdk` 24, « desugaring » activé | Cible iOS 15.0 |

---

## 11. Langues et accessibilité

- **Langues :** tous les textes sont dans `lib/app/l10n/` (fichiers ARB, outil officiel `gen-l10n`). Aucun texte écrit en dur dans un écran. Français seul dans le MVP.
- **Accessibilité :** libellés `Semantics` pour TalkBack et VoiceOver, respect de la taille de texte du système (pas de hauteurs fixes), zones tactiles d'au moins 48 dp, contrastes conformes au niveau AA, composants `.adaptive` pour les interrupteurs et les boîtes de dialogue.

---

## 12. Préparation des évolutions

| Évolution | Ce qui est prévu dès maintenant | Ce qui n'est **pas** fait dans le MVP |
|---|---|---|
| Freemium | Interface `EntitlementService` (répond toujours « gratuit ») | Aucun achat, aucune fonction Premium affichée ou simulée |
| Synchronisation | Interface `SyncService` ; identifiants universels (UUID), dates de modification, chemins relatifs, fichiers déjà chiffrés sur l'appareil | Aucun envoi, aucun service choisi |
| OCR | Interface `OcrService`, champ `contentIndex`, index de recherche déjà capable d'indexer ce texte | Aucun appel à ML Kit Text Recognition |
| Sous-catégories | Ajout possible par une simple migration de la base | — |
| Autres formats de fichier | Liste des formats centralisée (type, signature, lecteur associé) | Seuls PDF, JPEG et PNG sont acceptés |

---

## 13. Stratégie de tests

| Niveau | Ce qui est testé | Comment |
|---|---|---|
| Unitaire | Chiffrement (aller-retour, fichier modifié, tronqué, mauvais PIN), gestion des clés, changement de PIN, récupération, repositories, calcul des rappels, recherche, validation des fichiers | `flutter test`, base drift en mémoire |
| Widgets | Onboarding, clavier PIN, listes (vide, chargement, erreur), formulaires | Services simulés injectés par Riverpod |
| Intégration | Création du coffre → import d'un PDF → vérification que le fichier sur disque est bien chiffré → recherche → export → verrouillage et déverrouillage | `integration_test` sur émulateur et téléphone |
| Sécurité | Liste détaillée dans [04-securite.md](04-securite.md) | Unitaire + intégration + vérifications manuelles |

Le scanner, le sélecteur de fichiers et les notifications étant derrière des interfaces, les tests automatiques utilisent des versions simulées qui renvoient des fichiers d'exemple. Le vrai scanner est vérifié à la main sur téléphone.

Couverture mesurée avec `flutter test --coverage`.
