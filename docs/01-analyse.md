# Phase 1 – Analyse du cahier des charges

Document rédigé le 13/11/2026. Référence : [cahier-des-charges.md](cahier-des-charges.md) (version 1.1).

Ce document résume ce que j'ai compris, l'état de l'environnement, les choix que je propose et les risques. Les autres documents de la phase 1 entrent dans le détail :

| Document | Contenu |
|---|---|
| [02-architecture.md](02-architecture.md) | Organisation du code, modules, navigation |
| [03-modele-de-donnees.md](03-modele-de-donnees.md) | Tables, relations, fichiers sur le téléphone |
| [04-securite.md](04-securite.md) | Règles de sécurité, analyse des risques, limites |
| [05-parcours-utilisateurs.md](05-parcours-utilisateurs.md) | Ce que fait l'utilisateur, écran par écran |
| [06-dependances.md](06-dependances.md) | Paquets retenus et pourquoi |
| [guide-installation-windows.md](guide-installation-windows.md) | Installer l'environnement de développement |

---

## 1. Ce que j'ai compris

DocSafe est un coffre-fort de documents sur téléphone. Trois idées dominent tout le reste :

1. **Tout reste sur le téléphone.** Pas de compte, pas de serveur, pas besoin d'Internet.
2. **Tout est chiffré.** Les fichiers, les miniatures, les titres, les tags et le texte extrait. Sans le code PIN (ou la biométrie, ou la clé de récupération), rien n'est lisible.
3. **Cela doit rester simple** et fluide, y compris sur un téléphone Android d'entrée de gamme.

Le MVP est développé et validé sur Android. Le code reste compatible iOS, mais iOS sera compilé plus tard (pas de Mac disponible).

---

## 2. État de l'environnement (vérifié le 13/11/2026)

| Élément | État | Détail |
|---|---|---|
| Windows 11 64 bits, 13,8 Go de RAM, Ryzen 7 | OK | Suffisant pour Flutter et l'émulateur |
| VS Code + extensions Dart et Flutter | OK | Extensions en version 3.146.0 |
| Git | OK | 2.52 |
| Android Studio | OK | Installé, avec Java 25 intégré (pris en charge par Flutter 3.50 d'après son code source ; `flutter doctor` le confirmera après l'installation) |
| SDK Android | Partiel | Plateforme Android 37, build-tools 36 et adb présents |
| Outils en ligne de commande du SDK (`cmdline-tools`) | **Manquant** | Nécessaire pour accepter les licences Android |
| Émulateur Android | **Non configuré** | Aucune image système, aucun appareil virtuel créé |
| **SDK Flutter** | **Manquant** | La commande `flutter` n'existe pas sur ce PC |
| Téléphone Android branché | Non détecté | À brancher au moment des tests |
| Disque C: | 31 Go libres | Un peu juste : je recommande d'installer Flutter sur D: (213 Go libres) |

**Conséquence :** rien ne bloque la phase 1 (conception) ni la phase 2 (design). En revanche **Flutter doit être installé avant la phase 3**. La marche à suivre est dans [guide-installation-windows.md](guide-installation-windows.md).

Version visée : **Flutter 3.50.0** (dernière version stable, publiée le 11/11/2026), avec **Dart 3.14**.

> **Mise à jour du 13/11/2026 (soir).** Flutter 3.50.0 a été téléchargé et extrait dans `D:\dev\flutter`, mais il ne peut pas s'exécuter : le PC est infecté par un virus qui contamine les programmes. La phase 3 est bloquée tant que le PC n'est pas nettoyé. Détail et marche à suivre dans [problemes-connus.md](problemes-connus.md).

---

## 3. Périmètre du MVP

Les 15 éléments obligatoires du cahier des charges (§7) et l'endroit où ils seront traités :

| # | Élément du MVP | Module | Phase |
|---|---|---|---|
| 1 | Onboarding | `features/onboarding` | 3 |
| 2 | Configuration du coffre-fort | `features/auth` + `core/security` | 3 |
| 3 | Protection biométrique et PIN | `features/auth` + `core/security` | 3 |
| 4 | Tableau de bord | `features/dashboard` | 4 |
| 5 | Scanner (avec solution de repli) | `features/scanner` | 4 |
| 6 | Importation PDF et images | `features/documents` (import) | 4 |
| 7 | Gestion des catégories | `features/categories` | 4 |
| 8 | Gestion des documents | `features/documents` | 4 |
| 9 | Stockage local chiffré | `core/security` + `core/storage` + `core/database` | 3 |
| 10 | Recherche locale | `features/search` | 4 |
| 11 | Favoris | `features/documents` | 4 |
| 12 | Dates d'expiration | `features/reminders` | 4 |
| 13 | Notifications locales | `features/reminders` + `core/platform` | 4 |
| 14 | Exportation et partage sécurisé | `features/documents` + `core/platform` | 4 |
| 15 | Paramètres | `features/settings` | 4 |

**Hors MVP, mais préparé dans l'architecture** (une interface existe, sans implémentation) : OCR, identification automatique du type de document, synchronisation cloud, achats intégrés, extension de partage iOS, sous-catégories.

---

## 4. Choix proposés

Le cahier des charges me demande, en cas d'ambiguïté, de proposer une solution justifiée et de la signaler. Voici la liste. Vous pouvez répondre simplement « OK pour tout » ou « pour D7, je préfère… ».

Deux points demandaient **votre réponse** : **D2** et **D13**.

> **Phase 1 validée le 13/11/2026.** Tous les choix ci-dessous sont retenus tels que proposés, y compris D2 (`com.docusafe.app`) et D13 (sauvegarde chiffrée dans le MVP). D2 reste modifiable jusqu'à la création du projet Flutter, en phase 3.

| N° | Sujet | Choix proposé | Pourquoi |
|---|---|---|---|
| D1 | Versions | Flutter 3.50 / Dart 3.14. Android minimum : **7.0 (API 24)**. iOS minimum : **15.0**. `compileSdk` 37, `targetSdk` 36. | Flutter 3.50 n'accepte plus les versions d'Android inférieures à 7.0, et tous les paquets retenus s'alignent dessus. Android 7.0 couvre la quasi-totalité des téléphones en service, y compris l'entrée de gamme. |
| **D2** | Identifiant de l'application | **À confirmer.** Je propose `com.docusafe.app`. Nom du projet Dart : `docusafe`. | Cet identifiant est **définitif** une fois l'application publiée. Si vous possédez un nom de domaine, il est d'usage de l'utiliser à l'envers (ex. `com.monentreprise.docsafe`). |
| D3 | Base de données | `drift` + `sqlite3` avec le moteur **SQLite3MultipleCiphers** : la base entière est chiffrée, pas seulement quelques champs. | Le paquet `sqlcipher_flutter_libs` (qui correspond au « SQLCipher » du cahier des charges) est officiellement en fin de vie. Son remplaçant est intégré au paquet `sqlite3`. Chiffrer toute la base protège aussi les titres, les tags et l'index de recherche. |
| D4 | Scanner | Paquet **`cunning_document_scanner`**. | Il utilise ML Kit sur Android et VisionKit sur iOS, exactement comme demandé, et il contient déjà la solution de repli (recadrage manuel) pour les téléphones sans services Google Play. `google_mlkit_document_scanner` ne couvre toujours qu'Android. |
| D5 | Code PIN | **6 chiffres minimum** (jusqu'à 12). Les codes trop simples (`000000`, `123456`…) sont refusés. | Un code à 4 chiffres n'offre que 10 000 combinaisons : trop peu pour un coffre-fort. |
| D6 | Clé de récupération | Générée **automatiquement à la création du coffre**. **Révision du 14/11/2026 (décision du développeur, choix délégué) :** elle n'est plus une étape obligatoire de l'inscription. Elle est créée en silence ; un rappel sur l'accueil et dans les réglages invite à la noter, jusqu'à ce que l'utilisateur confirme l'avoir conservée. Elle est affichée une seule fois. | C'est le seul moyen de retrouver l'accès si le PIN est oublié, et la sauvegarde chiffrée (D13) ne se restaure qu'avec elle. La rendre discrète allège l'inscription sans rien retirer à la sécurité ; le risque accepté est qu'un utilisateur ignore le rappel. |
| D7 | Biométrie | Clé protégée **par le matériel du téléphone** et libérée uniquement après une vraie authentification biométrique. Disponible sur **Android 9 et plus** et sur iOS. Sur Android 7 et 8 : PIN uniquement. | Une biométrie qui ne ferait qu'afficher une fenêtre « OK » serait contournable sur un téléphone compromis. Le paquet de stockage sécurisé n'assure cette protection matérielle qu'à partir d'Android 9. |
| D8 | Internet | L'application publiée **ne demande pas la permission Internet**. | Garantie simple et vérifiable : DocSafe ne peut techniquement rien envoyer. La permission sera ajoutée le jour où la synchronisation ou les achats intégrés arriveront. |
| D9 | Notifications | Texte **générique par défaut** (« Un document arrive à échéance dans 30 jours »), sans le nom du document. Option pour afficher le nom. Alarmes « inexactes ». | Une notification s'affiche sur l'écran verrouillé et le système la stocke en clair. Un rappel à 30 jours n'a pas besoin d'être exact à la minute, ce qui évite une permission sensible et contrôlée par Google Play. |
| D10 | Suppression d'une catégorie | L'application demande où déplacer les documents (par défaut : « Autres »). La catégorie « Autres » ne peut pas être supprimée. | Le cahier des charges interdit de supprimer les documents avec la catégorie. |
| D11 | Champs ajoutés au modèle de données | `docType` (type de document), `lastOpenedAt`, `pageCount`, et quelques champs techniques pour les rappels et les catégories. | Nécessaires pour des fonctions demandées : « Type de document » (§3.6), « Documents consultés récemment » (§3.11), annulation d'un rappel. Détail dans [03-modele-de-donnees.md](03-modele-de-donnees.md). |
| D12 | Verrouillage automatique | Immédiat quand l'application passe en arrière-plan. Après **2 minutes** d'inactivité à l'écran (réglable : 30 s, 1, 2, 5 ou 10 min). | Équilibre entre sécurité et confort de lecture d'un document. Une tolérance est prévue pendant le scanner, le sélecteur de fichiers et le partage (voir [04-securite.md](04-securite.md)). |
| **D13** | Sauvegarde chiffrée manuelle | **À décider.** Je recommande de l'inclure dans le MVP : un fichier de sauvegarde chiffré que l'utilisateur enregistre où il veut et peut restaurer sur un autre téléphone avec sa clé de récupération. | Comme les sauvegardes automatiques d'Android sont désactivées (exigence de sécurité), **un téléphone perdu ou cassé signifie aujourd'hui la perte de tous les documents**. C'est le risque le plus sérieux pour vos utilisateurs. Coût estimé : modéré. |
| D14 | Langues | Tous les textes sont placés dans des fichiers de traduction dès le départ. Seul le français est fourni dans le MVP. | Ajouter l'anglais plus tard ne demandera aucune modification du code. |
| D15 | Police | Police système (Roboto sur Android, SF sur iPhone). | Aucune dépendance, respect automatique de la taille de texte choisie par l'utilisateur, rendu natif sur chaque plateforme. |
| D16 | Qualité du code | `flutter_lints` + quelques règles supplémentaires (interdiction de `print`, etc.). | `very_good_analysis` est plus strict mais ralentit un développeur seul sans bénéfice pour la sécurité. |
| D17 | Git | Je recommande d'initialiser un dépôt Git au début de la phase 3. | Historique, retour en arrière possible, et indispensable pour un service de build iOS comme Codemagic. |
| D18 | Phase 4 | Découpée en trois lots validés séparément : (a) catégories, documents, importation ; (b) scanner, recherche, favoris ; (c) échéances, notifications, partage, paramètres, tableau de bord. | La phase 4 contient l'essentiel de l'application. Des lots plus petits vous permettent de tester au fur et à mesure. |

---

## 5. Risques identifiés

| N° | Risque | Conséquence | Réponse prévue |
|---|---|---|---|
| R1 | Flutter n'est pas installé | Impossible de commencer la phase 3 | Guide d'installation fourni |
| R2 | iOS ne peut pas être testé (pas de Mac) | Bugs découverts tard | Code spécifique à iOS isolé et marqué « à vérifier sur iOS ». Build cloud (Codemagic) dès que possible. Deux paquets demandent une configuration iOS particulière (voir [06-dependances.md](06-dependances.md)). |
| R3 | Le paquet `cryptography_flutter` évolue lentement (dernière version : novembre 2025). **Mise à jour du 15/11/2026 : paquet retiré, voir 08-tests-et-risques.md.** | Risque de blocage lors d'une future mise à jour de Flutter | Tout le chiffrement passe par une interface unique (`CryptoEngine`). Plan B déjà identifié : `webcrypto` (maintenu par Google). Test de compilation et mesure de vitesse dès le début de la phase 3. |
| R4 | Téléphones d'entrée de gamme lents | PIN long à vérifier, chiffrement lent | Calculs lourds dans des isolates (hors de l'interface). Paramètres réglés sur un vrai téléphone d'entrée de gamme. |
| R5 | Scanner ML Kit indisponible (pas de services Google Play, ou moins de 1,7 Go de RAM) | Pas de détection automatique des contours | Le paquet bascule tout seul sur un scanner à recadrage manuel. À tester sur un émulateur sans Google Play. |
| R6 | Certains fabricants (Tecno, Infinix, Itel, Xiaomi…) arrêtent les tâches de fond pour économiser la batterie | Rappels en retard ou absents | L'onglet « Échéances » reste la référence et les rappels sont replanifiés à chaque ouverture. Limite documentée. |
| R7 | L'utilisateur perd son PIN **et** sa clé de récupération | Documents définitivement inaccessibles | Explication claire à la création du coffre (exigée par le cahier des charges). Aucun contournement possible : c'est le prix d'un vrai chiffrement. |
| R8 | Fichiers en clair pendant un court instant (sortie du scanner, fichier choisi, fichier partagé) | Fuite possible | Dossier temporaire privé, purge après chaque opération, au verrouillage et au démarrage. |
| R9 | Les paquets ont beaucoup évolué récemment (versions majeures récentes) | Exemples trouvés sur Internet souvent périmés | Je lis la documentation de la version exacte avant d'écrire le code. Versions figées dans `pubspec.lock`. |
| R10 | Nom « DocSafe » | D'autres produits portent un nom proche | À vérifier avant la publication (Google Play, App Store, marques déposées dans vos pays cibles). Ce point relève d'un conseil juridique, pas de la technique. |
| R11 | Exigences des magasins (niveau d'API cible, formulaires de confidentialité) | Refus à la soumission | Vérification des règles en vigueur en phase 6. |

---

## 6. Suite prévue

| Phase | Ce que je produirai | Ce dont j'ai besoin |
|---|---|---|
| 2 – Design | Système de design (couleurs, typographie, composants), maquettes des écrans en clair et en sombre, navigation | Votre validation de la phase 1 |
| 3 – Socle | Projet Flutter, configuration Android et iOS, chiffrement, clés, base de données, PIN, biométrie, onboarding, écran de verrouillage, premiers tests | **Flutter installé**, réponse à D2 |
| 4 – Fonctionnel (3 lots) | Toutes les fonctions du MVP | Un téléphone Android branché pour les tests |
| 5 – Sécurité et optimisation | Tests complets, analyse des risques finale, optimisation sur entrée de gamme, rapport de couverture | Si possible, un téléphone d'entrée de gamme |
| 6 – Publication | APK et AAB signés, fiches des magasins, politique de confidentialité, icône, captures d'écran | Compte développeur Google Play |
