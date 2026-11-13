# CAHIER DES CHARGES FONCTIONNEL ET TECHNIQUE

## DOCUSAFE – Application mobile Flutter de gestion et de sécurisation documentaire

> Copie de référence du cahier des charges fourni par le développeur le 13/11/2026.
> Le texte est repris tel quel ; seule la mise en forme (titres, listes, tableaux) a été adaptée au format Markdown.

- **Version :** 1.1 (adaptation Flutter)
- **Type de projet :** Application mobile multiplateforme développée avec Flutter
- **Nom commercial :** DocuSafe
- **Plateformes cibles :** Android en priorité (MVP), puis iPhone (iOS) avec le même code
- **Langue initiale :** Français
- **Marché cible :** International, avec une attention particulière aux marchés africains
- **Statut :** Spécification de référence pour le développement

---

## 0. CONTEXTE DE DÉVELOPPEMENT (À LIRE EN PREMIER)

### 0.1. Environnement du développeur

* Le développement se fait sur un PC Windows (64 bits).
* Éditeur : Visual Studio Code avec les extensions Flutter et Dart.
* Android Studio est installé pour le SDK Android et l’émulateur.
* Les tests se font sur l’émulateur Android et sur un téléphone Android réel branché en USB.
* Aucun Mac n’est disponible pour le moment.

### 0.2. Conséquences pour l’agent

* Le MVP doit être entièrement développé, lancé et testé sur Android.
* Le code doit rester compatible iOS dès le départ (dossier ios/ configuré, permissions iOS déclarées). La compilation et les tests iOS seront faits plus tard, sur un Mac ou via un service de build dans le cloud (par exemple Codemagic).
* Tout code spécifique à une plateforme doit être isolé, documenté et signalé comme « à vérifier sur iOS » s’il n’a pas pu être testé.
* Les commandes à exécuter doivent être données pour Windows (PowerShell ou terminal de VS Code).

### 0.3. Communication avec le développeur

* Expliquer en français simple.
* Avant chaque phase, annoncer ce qui va être fait.
* Après chaque phase, résumer ce qui a été fait, la liste des fichiers créés ou modifiés, et les commandes à lancer (flutter pub get, flutter run, flutter test…).
* Attendre la validation du développeur avant de passer à la phase suivante.

---

## 1. PRÉSENTATION GÉNÉRALE DU PROJET

### 1.1. Contexte

La conservation des documents personnels et professionnels constitue un besoin quotidien. Les utilisateurs stockent actuellement leurs documents dans différents endroits : galeries photos, applications de messagerie, services cloud, dossiers physiques et espaces de stockage divers.

Cette dispersion entraîne plusieurs difficultés :

* Perte ou suppression accidentelle de documents.
* Difficulté à retrouver rapidement une pièce justificative.
* Absence de classement structuré.
* Exposition de documents confidentiels.
* Oubli des dates d’expiration.
* Difficulté à conserver des documents accessibles hors connexion.

DocuSafe a pour ambition de répondre à ces problèmes à travers une application mobile sécurisée, simple, moderne et intelligente.

### 1.2. Vision du produit

DocuSafe est un coffre-fort documentaire numérique permettant à chaque utilisateur de numériser, importer, organiser, consulter, rechercher et protéger ses documents personnels et professionnels depuis son téléphone (Android ou iPhone).

L’application doit privilégier le stockage local sécurisé et le fonctionnement hors ligne.

La synchronisation cloud constitue une fonctionnalité complémentaire et facultative.

### 1.3. Objectifs généraux

1. Centraliser les documents importants dans un espace unique.
2. Garantir la confidentialité et l’intégrité des fichiers.
3. Faciliter la numérisation et la classification.
4. Retrouver rapidement un document grâce à une recherche intelligente.
5. Anticiper les expirations et échéances documentaires.
6. Permettre une utilisation sans connexion Internet.
7. Proposer une expérience utilisateur premium, conforme aux standards de chaque plateforme (Material Design sur Android, conventions Apple sur iPhone).
8. Construire un produit commercialisable sur le Google Play Store, puis sur l’App Store.

## 2. PUBLIC CIBLE

L’application s’adresse notamment à :

* Étudiants souhaitant conserver leurs diplômes, attestations et relevés de notes.
* Travailleurs souhaitant centraliser leurs contrats et documents professionnels.
* Entrepreneurs souhaitant conserver leurs documents administratifs et commerciaux.
* Voyageurs souhaitant garder leurs passeports, visas et justificatifs accessibles.
* Particuliers souhaitant numériser leurs documents personnels.
* Petites entreprises et indépendants ayant besoin d’un archivage documentaire simple.

## 3. FONCTIONNALITÉS FONCTIONNELLES

### 3.1. Authentification et première utilisation

L’application doit proposer une expérience d’accueil professionnelle.

Fonctionnalités :

* Écran de bienvenue présentant DocuSafe.
* Présentation des avantages principaux.
* Configuration initiale du coffre-fort.
* Création d’un code PIN local.
* Activation facultative de la biométrie (empreinte digitale ou reconnaissance faciale sur Android, Face ID ou Touch ID sur iPhone).
* Présentation des conditions de confidentialité.
* Explication du fonctionnement du stockage local.
* Possibilité de commencer sans créer de compte externe.

Règle importante : l’utilisateur doit pouvoir utiliser les fonctions principales sans inscription obligatoire ni connexion Internet.

La récupération d’accès doit être expliquée clairement : en cas de perte du code et d’absence de clé de récupération, les données chiffrées peuvent être définitivement inaccessibles.

### 3.2. Tableau de bord

Le tableau de bord constitue l’écran principal de l’application.

Il doit afficher :

* Le nom et l’identité visuelle de DocuSafe.
* Le nombre total de documents.
* Les catégories documentaires.
* Les documents récemment ajoutés.
* Les documents favoris.
* Les échéances à venir.
* Un accès rapide au scanner.
* Un accès à l’importation de fichiers.
* Une barre de recherche.

Le tableau de bord doit être personnalisable dans ses évolutions futures.

### 3.3. Numérisation des documents

Développer un scanner documentaire intégré utilisant les capacités natives de chaque plateforme.

Fonctionnalités obligatoires :

* Ouverture de l’appareil photo depuis l’application.
* Détection automatique des contours.
* Détection des pages.
* Correction de perspective.
* Recadrage manuel.
* Amélioration de la lisibilité.
* Conversion en PDF.
* Numérisation multipage.
* Prévisualisation avant enregistrement.
* Possibilité de recommencer une capture.
* Possibilité de réorganiser les pages.
* Enregistrement dans une catégorie.

Technologies à utiliser :

* Android : API Google ML Kit Document Scanner (détection des contours, correction de perspective, recadrage, filtres, multipage).
* iOS : VisionKit (VNDocumentCameraViewController).
* Utiliser un paquet Flutter maintenu qui couvre les deux plateformes. À défaut, créer un platform channel. Attention : le paquet google_mlkit_document_scanner ne couvre qu’Android.
* Si le scanner ne fournit pas directement un PDF, générer le PDF dans l’application (paquet pdf).
* Prévoir une solution de repli (prise de photo simple avec recadrage manuel) lorsque le scanner ML Kit n’est pas disponible, par exemple sur les téléphones sans services Google Play.

### 3.4. Importation des documents

L’utilisateur doit pouvoir importer des fichiers depuis :

* Le gestionnaire de fichiers (Android) et l’application Fichiers (iOS).
* La galerie photos (Android) et la photothèque (iOS).
* Les documents PDF.
* Les images compatibles.
* Les autres applications via le partage (« Partager vers DocuSafe ») : intent de partage sur Android, extension de partage sur iOS. L’extension de partage iOS peut être reportée après le MVP.

Formats initiaux à prendre en charge :

* PDF
* JPG / JPEG
* PNG

Prévoir une architecture extensible pour d’autres formats.

Les fichiers importés doivent être validés, contrôlés et chiffrés avant leur intégration au coffre-fort.

Paquets indicatifs : file_picker, image_picker, receive_sharing_intent.

### 3.5. Gestion des catégories

Créer les catégories initiales suivantes :

| Catégorie | Contenu |
|---|---|
| Identité | Passeport, carte d’électeur, pièces d’identité |
| Éducation | Diplômes, certificats, relevés |
| Professionnel | CV, contrats, attestations |
| Finances | Factures, reçus, justificatifs |
| Immobilier | Contrats de location, titres et documents immobiliers |
| Santé | Documents et dossiers personnels |
| Autres | Documents personnalisés |

Fonctionnalités :

* Ajouter une catégorie.
* Modifier une catégorie.
* Supprimer une catégorie.
* Choisir une icône.
* Choisir une couleur.
* Déplacer un document d’une catégorie à une autre.
* Créer des sous-catégories dans une évolution ultérieure.

La suppression d’une catégorie ne doit pas entraîner automatiquement la suppression de ses documents.

### 3.6. Gestion individuelle des documents

Chaque document doit posséder une fiche descriptive contenant :

* Identifiant unique.
* Nom du document.
* Type de document.
* Catégorie.
* Date d’ajout.
* Date de modification.
* Date d’émission facultative.
* Date d’expiration facultative.
* Description.
* Tags personnalisés.
* Statut favori.
* Chemin de stockage interne.
* Empreinte d’intégrité.
* Métadonnées nécessaires à son indexation.

Actions disponibles :

* Consulter.
* Renommer.
* Modifier les informations.
* Ajouter une description.
* Ajouter des tags.
* Mettre en favori.
* Partager après authentification.
* Exporter.
* Supprimer avec confirmation.

### 3.7. Sécurité documentaire

La sécurité représente l’un des piliers fondamentaux de DocuSafe.

Exigences :

**Authentification**

* Protection biométrique lorsque disponible (empreinte ou visage sur Android, Face ID ou Touch ID sur iPhone), via le paquet local_auth.
* Code PIN de secours.
* Verrouillage automatique après inactivité et lors du passage en arrière-plan.
* Nouvelle authentification avant les opérations sensibles.

**Chiffrement**

* Utilisation d’une bibliothèque cryptographique Dart reconnue (par exemple le paquet cryptography, avec cryptography_flutter pour l’accélération native).
* Chiffrement des fichiers au repos avec un algorithme robuste, par exemple AES-GCM.
* Gestion sécurisée des clés.
* Stockage des secrets dans le stockage sécurisé du système : Android Keystore sur Android, Keychain sur iOS (via le paquet flutter_secure_storage).
* Séparation entre les clés de chiffrement et les données documentaires.
* Vérification d’intégrité lors du déchiffrement (par exemple empreinte SHA-256 avec le paquet crypto).

**Protection supplémentaire**

* Exclusion des documents sensibles des sauvegardes non maîtrisées. Android : désactiver ou limiter la sauvegarde automatique (allowBackup et règles d’extraction des données). iOS : exclure les fichiers de la sauvegarde iCloud.
* Masquage du contenu confidentiel dans l’aperçu des applications récentes. Android : FLAG_SECURE (bloque aussi les captures d’écran, à rendre configurable). iOS : écran de masquage quand l’application devient inactive.
* Protection des échanges entre l’application et les services externes.
* Absence de données documentaires sensibles dans les journaux techniques (aucun print ou debugPrint de contenu sensible).
* Gestion sécurisée des fichiers temporaires.

Ne jamais stocker un document sensible en clair dans un répertoire accessible sans protection.

Ne pas considérer la biométrie (empreinte, Face ID) comme un mécanisme de chiffrement : elle sert à autoriser l’accès à une clé protégée.

### 3.8. Recherche intelligente

Développer un moteur de recherche local.

L’utilisateur doit pouvoir rechercher :

* Par nom de document.
* Par catégorie.
* Par date.
* Par mot-clé.
* Par tag.
* Par texte extrait du document lorsque l’OCR est disponible.

La recherche doit fonctionner hors ligne.

### 3.9. Reconnaissance automatique des documents (OCR)

Utiliser Google ML Kit Text Recognition (paquet google_mlkit_text_recognition), qui fonctionne directement sur l’appareil, sans Internet, sur Android et sur iOS.

Fonctionnalités :

* Reconnaissance du texte.
* Extraction des informations pertinentes.
* Identification indicative du type de document.
* Indexation du texte pour la recherche.
* Proposition automatique d’une catégorie.
* Validation manuelle par l’utilisateur.

Exemple :

Lorsqu’un utilisateur importe un diplôme, l’application peut proposer :

* Type : diplôme.
* Catégorie : éducation.
* Établissement : valeur détectée.
* Nom du titulaire : valeur détectée.
* Date d’émission : valeur détectée.

Les informations reconnues doivent toujours être présentées comme des propositions à vérifier. L’application ne doit pas prétendre authentifier un diplôme ou certifier l’authenticité d’un document.

L’OCR doit être exécuté localement lorsque possible.

### 3.10. Gestion des dates d’expiration

L’utilisateur peut associer une échéance à chaque document.

Exemples :

* Passeport.
* Visa.
* Carte professionnelle.
* Assurance.
* Contrat.
* Permis.

Le système doit proposer des rappels configurables.

Configuration par défaut :

* 90 jours avant expiration.
* 30 jours avant expiration.
* 7 jours avant expiration.
* Le jour de l’expiration.

Les notifications doivent être locales et fonctionner sans connexion Internet, sous réserve des autorisations du système (Android 13 et plus : autorisation des notifications, et alarmes exactes si nécessaire ; iOS : autorisation des notifications).

Les rappels doivent être reprogrammés après un redémarrage du téléphone (Android).

L’utilisateur doit pouvoir modifier ou désactiver les rappels.

Paquets indicatifs : flutter_local_notifications et timezone.

### 3.11. Favoris et documents récents

Créer deux espaces distincts :

**Favoris**

* Documents fréquemment utilisés.
* Accès rapide.
* Possibilité d’ajouter et de retirer des favoris.

**Récents**

* Documents consultés récemment.
* Documents ajoutés récemment.
* Tri chronologique.

### 3.12. Exportation et partage

Permettre à l’utilisateur de partager un document après une authentification appropriée.

Fonctionnalités :

* Export PDF.
* Export image lorsque pertinent.
* Partage via la feuille de partage native du système (paquet share_plus).
* Export temporaire contrôlé.
* Suppression des fichiers temporaires après utilisation.

Afficher un avertissement avant le partage d’un document confidentiel.

Le partage constitue une sortie volontaire du coffre-fort : un fichier exporté ne bénéficie plus automatiquement de la protection de DocuSafe.

### 3.13. Paramètres

Prévoir les sections suivantes :

* Profil local.
* Sécurité.
* Biométrie (empreinte, visage, Face ID).
* Code PIN.
* Délai de verrouillage automatique.
* Notifications.
* Gestion du stockage.
* Exportation des données.
* Sauvegarde et synchronisation.
* Confidentialité.
* Conditions d’utilisation.
* À propos.
* Assistance.

## 4. ARCHITECTURE TECHNIQUE

### 4.1. Technologies imposées ou privilégiées

L’application doit être développée avec Flutter (dernière version stable) en langage Dart, avec un seul code source pour Android et iOS.

| Domaine | Technologie |
|---|---|
| Framework | Flutter (canal stable) |
| Langage | Dart (null safety) |
| Interface | Widgets Flutter, Material 3, composants adaptatifs pour iOS |
| IDE | Visual Studio Code (+ Android Studio pour le SDK Android et l’émulateur) |
| Architecture | MVVM avec séparation par modules (features) |
| Gestion d’état | Riverpod |
| Navigation | go_router |
| Base de données | SQLite via drift (avec chiffrement de la base, par exemple SQLCipher, ou chiffrement des champs sensibles) |
| Stockage des fichiers | path_provider + dart:io |
| Cryptographie | cryptography (+ cryptography_flutter) |
| Gestion des clés | flutter_secure_storage (Android Keystore / iOS Keychain) |
| Biométrie | local_auth |
| Scanner | ML Kit Document Scanner (Android) / VisionKit (iOS) |
| OCR | google_mlkit_text_recognition |
| Notifications | flutter_local_notifications + timezone |
| Import et partage | file_picker, image_picker, receive_sharing_intent, share_plus |
| PDF | pdf (création), pdfrx ou équivalent (affichage) |
| Synchronisation future | À choisir plus tard (iCloud, Google Drive, Firebase, Supabase…), avec chiffrement sur l’appareil |
| Achats intégrés | in_app_purchase (App Store et Google Play) |
| Tests | flutter_test, integration_test, mocktail |
| Qualité du code | flutter_lints (ou very_good_analysis) |

Les noms de paquets sont donnés à titre indicatif. Avant d’ajouter un paquet, vérifier sur pub.dev qu’il est maintenu, compatible avec la version stable de Flutter, qu’il couvre Android et iOS, et que sa licence permet un usage commercial.

Le choix final des bibliothèques doit être justifié dans la documentation technique.

Éviter les dépendances externes inutiles.

### 4.2. Architecture logique

Organiser le projet selon les responsabilités suivantes :

**Presentation Layer**

* Écrans (widgets).
* ViewModels (Notifiers Riverpod).
* Navigation (go_router).
* Composants UI réutilisables.

**Domain Layer**

* Entités métier.
* Cas d’utilisation.
* Interfaces des services.
* Règles métier.

**Data Layer**

* Repositories.
* Gestion de la base de données.
* Gestion des fichiers.
* Persistance locale.

**Security Layer**

* Chiffrement et déchiffrement.
* Gestion des clés.
* Authentification biométrique.
* Verrouillage du coffre-fort.

**Platform Services**

* Scanner.
* OCR.
* Notifications.
* Partage.
* Importation et exportation.
* Code spécifique Android et iOS (platform channels si nécessaire).

Chaque module doit avoir une responsabilité clairement définie.

Structure de dossiers proposée :

```
lib/
  main.dart
  app/ (thème, routes, configuration)
  core/ (sécurité, base de données, stockage, erreurs, utilitaires)
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
    (chaque feature contient : presentation/, domain/, data/)
test/
integration_test/
```

### 4.3. Modèle de données

Créer au minimum les entités suivantes :

**Document**

* id
* title
* categoryId
* fileName
* encryptedFilePath
* fileType
* fileSize
* createdAt
* updatedAt
* issueDate
* expirationDate
* description
* isFavorite
* contentIndex
* integrityHash

**Category**

* id
* name
* icon
* color
* createdAt

**Tag**

* id
* name

**DocumentTag**

* documentId
* tagId

**Reminder**

* id
* documentId
* reminderDate
* isEnabled

**VaultSettings**

* id
* biometricEnabled
* autoLockDuration
* notificationsEnabled
* vaultConfiguration

Les entités métier sont des classes Dart immuables. Les tables sont définies avec drift.

Les relations et contraintes d’intégrité doivent être correctement définies.

Le texte OCR doit également bénéficier d’une protection adaptée puisqu’il peut contenir des informations sensibles.

### 4.4. Fonctionnement hors ligne

L’application doit fonctionner sans serveur obligatoire.

Les opérations suivantes doivent être disponibles hors connexion :

* Scanner.
* Importer.
* Classer.
* Consulter.
* Rechercher.
* Modifier les métadonnées.
* Supprimer.
* Chiffrer et déchiffrer.
* Recevoir les rappels locaux.

L’architecture doit permettre d’ajouter ultérieurement une synchronisation sans reconstruire toute l’application.

### 4.5. Synchronisation future

Prévoir une architecture permettant de proposer une synchronisation cloud facultative. Le service sera choisi plus tard (iCloud, Google Drive, Firebase, Supabase…). Prévoir une interface SyncService indépendante du service choisi.

Exigences :

* Synchronisation sécurisée.
* Gestion des conflits.
* Préservation du chiffrement.
* Gestion des suppressions.
* Gestion des appareils autorisés.
* Possibilité de désactiver la synchronisation.

Ne pas prétendre qu’un service cloud assure automatiquement un chiffrement de bout en bout personnalisé. Les documents doivent être chiffrés sur l’appareil avant tout envoi, et le mécanisme de gestion des clés doit être conçu explicitement.

## 5. INTERFACE UTILISATEUR ET EXPÉRIENCE

### 5.1. Direction artistique

DocuSafe doit présenter une identité visuelle moderne, minimaliste et professionnelle.

L’application doit inspirer :

* Confiance.
* Sécurité.
* Simplicité.
* Confidentialité.
* Fiabilité.

Orientation graphique :

* Interface moderne basée sur Material 3, avec des comportements adaptés à chaque plateforme (par exemple les composants .adaptive pour les interrupteurs et les boîtes de dialogue sur iPhone).
* Typographie : police système de chaque plateforme (Roboto sur Android, SF Pro sur iPhone) ou une police libre unique comme Inter. Ne pas intégrer SF Pro dans la version Android (police réservée aux plateformes Apple).
* Espacements cohérents.
* Icônes sobres.
* Animations fluides.
* Cartes documentaires élégantes.
* Hiérarchie visuelle claire.
* Respect des modes clair et sombre.

Éviter les interfaces surchargées, les dégradés excessifs et les éléments décoratifs inutiles.

### 5.2. Navigation principale

Prévoir une barre de navigation inférieure (NavigationBar Material 3) avec cinq espaces :

1. Accueil.
2. Documents.
3. Scanner.
4. Échéances.
5. Paramètres.

Le bouton Scanner doit être facilement identifiable et accessible.

### 5.3. Écrans à développer

L’agent devra concevoir et développer les écrans suivants :

1. Splash Screen.
2. Onboarding.
3. Configuration du coffre-fort.
4. Authentification.
5. Tableau de bord.
6. Liste des documents.
7. Détail d’un document.
8. Scanner.
9. Prévisualisation du scan.
10. Importation.
11. Création et modification de catégories.
12. Recherche.
13. Favoris.
14. Documents récents.
15. Échéances.
16. Gestion des rappels.
17. Paramètres de sécurité.
18. Paramètres généraux.
19. Gestion du stockage.
20. Écran de confirmation de suppression.
21. Écrans d’erreurs et d’états vides.

Tous les écrans doivent être fonctionnels, pas uniquement représentatifs.

## 6. EXIGENCES NON FONCTIONNELLES

### 6.1. Performance

* Ouverture rapide du tableau de bord.
* Recherche locale fluide.
* Chargement progressif des documents.
* Traitement asynchrone des opérations lourdes (chiffrement, OCR, génération de PDF), hors du thread principal (isolates).
* Optimisation de la mémoire.
* Gestion des documents volumineux.
* Prévisualisation sans déchiffrer inutilement tous les fichiers.
* Fluidité sur les téléphones Android d’entrée de gamme (peu de mémoire et de stockage), courants sur les marchés africains.

### 6.2. Fiabilité

* Gestion des erreurs de stockage.
* Prévention des fichiers corrompus.
* Vérification des opérations d’écriture.
* Transactions cohérentes.
* Protection contre les suppressions accidentelles.
* Gestion des interruptions pendant le chiffrement.

### 6.3. Accessibilité

* Respect de la taille de texte choisie dans le système (taille de police sur Android, Dynamic Type sur iOS).
* Compatibilité avec les lecteurs d’écran TalkBack (Android) et VoiceOver (iOS), grâce aux widgets Semantics.
* Contrastes suffisants.
* Zones tactiles adaptées.
* Interface compréhensible.

### 6.4. Compatibilité

* Téléphones Android (priorité du MVP).
* iPhone (deuxième étape, avec le même code).
* Versions récentes d’Android et d’iOS.
* Interface adaptée aux différentes tailles d’écran.
* Respect des exigences actuelles de Google Play (niveau d’API cible) et d’Apple.

La version minimale d’Android (minSdkVersion) et d’iOS doit être déterminée en fonction des paquets retenus et des appareils visés, en gardant à l’esprit les téléphones d’entrée de gamme.

## 7. PÉRIMÈTRE DE LA PREMIÈRE VERSION (MVP)

L’agent ne doit pas chercher à tout développer simultanément.

La première version doit obligatoirement contenir :

1. Onboarding.
2. Configuration du coffre-fort.
3. Protection biométrique et PIN.
4. Tableau de bord.
5. Scanner documentaire (avec solution de repli).
6. Importation PDF et images.
7. Gestion des catégories.
8. Gestion des documents.
9. Stockage local chiffré.
10. Recherche locale.
11. Favoris.
12. Dates d’expiration.
13. Notifications locales.
14. Exportation et partage sécurisé.
15. Paramètres.

Le MVP est d’abord validé sur Android. La version iOS est compilée et testée dans un second temps, avec le même code.

L’OCR avancé, l’identification automatique des documents et la synchronisation cloud peuvent être introduits progressivement, après validation de la sécurité et de la stabilité du MVP.

## 8. MODÈLE ÉCONOMIQUE

Prévoir une architecture permettant une monétisation Freemium.

**Version gratuite**

* Scanner.
* Importer.
* Organiser.
* Rechercher.
* Protéger.
* Consulter les échéances.

**Version Premium envisagée**

* OCR avancé.
* Recherche plein texte avancée.
* Synchronisation multi-appareils.
* Fonctionnalités avancées de sauvegarde.
* Outils de classification intelligente.

Les tarifs ne sont pas définitifs.

L’agent doit préparer une architecture permettant d’intégrer ultérieurement les achats intégrés via le paquet in_app_purchase (App Store et Google Play Billing).

Ne pas implémenter de paiement fictif ni de fonctionnalités Premium simulées dans la version de production.

## 9. SÉCURITÉ, CONFIDENTIALITÉ ET CONFORMITÉ

Compte tenu de la nature des données stockées, la sécurité doit être traitée comme une exigence prioritaire.

L’agent devra :

* Effectuer une analyse des risques.
* Identifier les données sensibles.
* Documenter les flux de données.
* Mettre en œuvre le chiffrement.
* Protéger les clés.
* Tester les mécanismes d’authentification.
* Vérifier les permissions.
* Contrôler les fichiers temporaires.
* Éviter les fuites dans les logs.
* Prévoir la suppression sécurisée des clés et données locales.
* Documenter les limites de sécurité.

Préparer également :

* Politique de confidentialité.
* Conditions d’utilisation.
* Formulaire « Sécurité des données » de Google Play.
* Déclarations de confidentialité App Store.
* Justification des permissions Android (AndroidManifest.xml) et iOS (Info.plist).
* Informations relatives aux achats intégrés si activés.

Aucune donnée documentaire ne doit être envoyée à un service externe sans consentement explicite et information claire de l’utilisateur.

## 10. TESTS ET VALIDATION

L’application doit faire l’objet de plusieurs niveaux de tests.

**Tests unitaires (flutter_test)**

* Création de documents.
* Modification.
* Suppression.
* Classification.
* Recherche.
* Gestion des dates.
* Chiffrement et déchiffrement.
* Gestion des clés.

**Tests d’intégration (integration_test, sur émulateur et téléphone Android)**

* Scanner vers stockage.
* Importation vers stockage.
* OCR vers index de recherche.
* Notifications.
* Exportation.
* Gestion de la base de données.

**Tests de sécurité**

* Accès sans authentification.
* Mauvaise saisie du PIN.
* Verrouillage automatique.
* Vérification du chiffrement des fichiers.
* Vérification des journaux.
* Gestion des fichiers temporaires.
* Corruption de fichiers.
* Interruption d’une opération.

**Tests d’interface (tests de widgets et integration_test)**

* Navigation complète.
* Onboarding.
* Ajout d’un document.
* Recherche.
* Scanner.
* Modification.
* Suppression.
* Exportation.

## 11. CRITÈRES D’ACCEPTATION

Le MVP ne sera considéré comme terminé que si :

1. L’application compile sans erreur et la commande flutter analyze ne signale aucune erreur.
2. L’application se lance sur l’émulateur Android et sur un téléphone Android réel.
3. Un build de version Android (APK et AAB release) est généré sans erreur.
4. L’utilisateur peut créer un coffre-fort local.
5. Il peut scanner un document.
6. Il peut importer un PDF.
7. Il peut classer ses documents.
8. Il peut consulter ses documents hors ligne.
9. Les fichiers stockés sont effectivement chiffrés.
10. L’authentification protège réellement l’accès.
11. Il peut retrouver un document.
12. Les rappels locaux fonctionnent.
13. L’exportation est opérationnelle.
14. Les erreurs sont correctement gérées.
15. Les tests critiques passent.
16. L’application ne présente aucun blocage critique connu.
17. L’interface est cohérente et adaptée à Android et à iOS.
18. Le projet iOS est configuré (permissions, identifiant de l’application) et prêt à être compilé sur un Mac ou via un service de build dans le cloud.

## 12. LIVRABLES ATTENDUS

L’agent devra fournir :

* Projet Flutter complet (lib/, android/, ios/, pubspec.yaml).
* Code source Dart.
* Architecture documentée.
* Modèle de données.
* Documentation des modules.
* Documentation de sécurité.
* Tests unitaires.
* Tests de widgets.
* Tests d’intégration.
* Rapport de couverture des tests (flutter test --coverage).
* Guide d’installation de l’environnement sur Windows.
* Guide de compilation (Android ; iOS via Mac ou service de build dans le cloud).
* Guide de configuration.
* Rapport des problèmes connus.
* Liste des dépendances (paquets pub.dev avec justification).
* Assets graphiques.
* Icône d’application pour Android et iOS.
* Captures d’écran destinées à Google Play et à l’App Store.
* Description commerciale de l’application pour Google Play et l’App Store.
* Politique de confidentialité à faire valider.
* Build Android de test (APK pour l’installation directe, AAB pour le test interne Google Play).
* Build iOS destiné à TestFlight, dès qu’un Mac ou un service de build dans le cloud sera disponible.

La publication sur Google Play nécessitera un compte développeur Google Play. La publication sur l’App Store nécessitera la validation et les accès du propriétaire du compte Apple Developer.

## 13. MÉTHODOLOGIE DE DÉVELOPPEMENT

Le développement doit être réalisé par phases.

**Phase 1 – Analyse et conception**

* Analyse du cahier des charges.
* Définition de l’architecture.
* Modélisation des données.
* Conception des parcours utilisateurs.
* Définition des règles de sécurité.

**Phase 2 – Design**

* Création du système de design (thème Material 3, couleurs, typographie, modes clair et sombre).
* Maquettes des écrans.
* Navigation.
* Composants réutilisables.

**Phase 3 – Développement du socle**

* Initialisation du projet Flutter (flutter create) et configuration Android et iOS.
* Architecture.
* Stockage.
* Base de données.
* Gestion des clés.
* Authentification.

**Phase 4 – Développement fonctionnel**

* Scanner.
* Importation.
* Classification.
* Consultation.
* Recherche.
* Favoris.
* Échéances.

**Phase 5 – Sécurité et optimisation**

* Tests.
* Corrections.
* Analyse des risques.
* Optimisation.

**Phase 6 – Préparation de publication**

* Vérification de la compatibilité.
* Tests sur plusieurs téléphones Android réels (dont un modèle d’entrée de gamme).
* Configuration de la Google Play Console et test interne.
* Ensuite : compilation iOS, configuration App Store Connect et préparation TestFlight.
* Préparation des dossiers de soumission.

Chaque phase doit faire l’objet d’une validation avant le passage à la suivante.

## 14. DIRECTIVES DE QUALITÉ

L’agent doit respecter les principes suivants :

* Ne jamais remplacer une fonctionnalité réelle par une simple simulation visuelle.
* Ne jamais utiliser de données fictives comme données de production.
* Ne pas laisser de boutons sans action.
* Ne pas introduire de dépendances sans justification.
* Ne pas ignorer les erreurs.
* Ne pas sacrifier la sécurité au profit de la rapidité.
* Ne pas créer une architecture inutilement complexe.
* Écrire un code lisible, modulaire et maintenable.
* Documenter les décisions techniques.
* Respecter les conventions Dart (Effective Dart) et les recommandations officielles de Flutter.
* Garder la commande flutter analyze sans erreur ni avertissement.

En cas d’ambiguïté, l’agent doit proposer une solution techniquement justifiée, signaler son choix et poursuivre sans bloquer inutilement le projet.

---

## 15. DÉFINITION DU RÉSULTAT FINAL

DocuSafe doit devenir une application mobile Flutter fiable, sécurisée et commercialisable, d’abord sur Android, puis sur iPhone.

Le résultat attendu est un véritable produit logiciel et non une simple démonstration d’interface.

La priorité absolue est la confidentialité des documents, le fonctionnement hors ligne, la simplicité d’utilisation et la qualité de l’expérience utilisateur.

Principe directeur : les documents de l’utilisateur lui appartiennent. DocuSafe doit les protéger sans rendre leur utilisation compliquée.
