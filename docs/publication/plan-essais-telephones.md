# Plan d'essais sur de vrais téléphones

Cahier des charges §13 (phase 6) : essais sur plusieurs téléphones Android réels, dont un modèle d'entrée de gamme. Ces essais couvrent ce que ni les tests automatiques ni le téléphone simulé ne peuvent vérifier.

## Téléphones

| Téléphone | Pourquoi | Exemple |
|---|---|---|
| **Entrée de gamme** (2 à 3 Go de mémoire, Android 8 à 11) | Vitesse du code et du chiffrement, petit écran, économie de batterie agressive | Tecno, Itel, Infinix, Samsung Galaxy A0x |
| **Récent** (Android 14 à 16) | Notifications, biométrie forte, pages mémoire de 16 Ko | Tout téléphone de moins de deux ans |
| *Facultatif* : sans services Google Play | Repli du scanner (recadrage manuel) | Certains Huawei |

## Installer

Installer l'APK « aperçu » (docs/apercu-telephone.md). Il s'installe à côté de la future vraie application. Les captures d'écran y sont autorisées et un journal technique est écrit : c'est voulu pour cette version de test.

## Essais

Pour chaque ligne, noter **OK** ou décrire le problème (capture d'écran, modèle du téléphone, version d'Android).

### Coffre et sécurité

| N° | Action | Résultat attendu | Mesure à noter |
|---|---|---|---|
| 1 | Créer le coffre avec un code de 6 chiffres | Accueil affiché | Durée entre « Continuer » et l'accueil |
| 2 | Verrouiller (cadenas), rouvrir avec le code | Coffre rouvert | Durée de déverrouillage |
| 3 | Taper 5 fois un faux code | Message « il reste … essais », puis attente de 30 s | |
| 4 | Activer l'empreinte (Paramètres → Sécurité), verrouiller, rouvrir avec l'empreinte | Coffre rouvert | |
| 5 | Ajouter une nouvelle empreinte dans les réglages du téléphone, revenir dans DocSafe | L'empreinte est refusée, le code est demandé | |
| 6 | Quitter DocSafe (bouton Accueil du téléphone), revenir | Coffre verrouillé | |
| 7 | Ne plus toucher l'écran pendant 2 minutes | Coffre verrouillé | |
| 8 | Noter la clé de récupération, puis « Code oublié ? » et la saisir | Choix d'un nouveau code, coffre ouvert | |

### Documents

| N° | Action | Résultat attendu | Mesure à noter |
|---|---|---|---|
| 9 | Importer un PDF de plusieurs pages | Miniature de la première page, fiche correcte | |
| 10 | Importer un PDF de 15 à 20 Mo | Import réussi | Durée de l'import |
| 11 | Ouvrir ce PDF, faire défiler toutes les pages | Affichage fluide | Durée d'ouverture |
| 12 | Importer une photo de la galerie | Miniature correcte, bien orientée | |
| 13 | Numériser 3 pages avec le scanner | Contours détectés, PDF de 3 pages dans le coffre | |
| 14 | Refuser l'accès à l'appareil photo, puis relancer le scanner | Message clair avec lien vers les réglages | |
| 15 | Rechercher un document par 3 lettres sans accent | Document trouvé | |
| 16 | Modifier, mettre en favori, déplacer, supprimer un document | Changements visibles partout | |

### Échéances et notifications

| N° | Action | Résultat attendu |
|---|---|---|
| 17 | Donner à un document une date d'expiration dans 7 jours ; régler l'heure des rappels quelques minutes plus tard | La demande d'autorisation des notifications apparaît une fois |
| 18 | Attendre l'heure du rappel, DocSafe fermé | Notification au texte générique (sans le nom du document) |
| 19 | Toucher la notification | Le code est demandé, puis la fiche du document s'ouvre |
| 20 | Redémarrer le téléphone avant l'heure d'un rappel | Le rappel arrive quand même (à noter : marque du téléphone si ce n'est pas le cas) |

### Partage, export, sauvegarde

| N° | Action | Résultat attendu |
|---|---|---|
| 21 | Partager un document par une messagerie | Avertissement, puis le destinataire reçoit le bon fichier |
| 22 | Exporter un document dans « Téléchargements » | Fichier lisible par une autre application |
| 23 | Exporter toutes les données | Fichier ZIP rangé par catégorie |
| 24 | Créer une sauvegarde, la copier sur un deuxième téléphone, l'y restaurer avec la clé de récupération | Tous les documents présents et lisibles |
| 25 | Paramètres → Stockage → Nettoyer | « Aucun fichier en attente » |
| 25 bis | Depuis la galerie ou l'application Fichiers : Partager → DocSafe, coffre verrouillé, puis coffre ouvert | Le code est demandé si besoin, puis l'écran d'importation s'ouvre avec le fichier |
| 25 ter | « Code oublié ? » sur l'écran de déverrouillage, saisir la clé de récupération | Choix d'un nouveau code, puis accueil |

### Affichage

| N° | Action | Résultat attendu |
|---|---|---|
| 26 | Mode sombre du téléphone | Tous les écrans lisibles |
| 27 | Plus grande taille de police du téléphone | Rien de coupé ni de superposé (noter les écrans concernés) |
| 28 | Icône sur l'écran d'accueil du téléphone, y compris avec les icônes à thème (Android 13 et plus) | Icône DocSafe nette |

## Après les essais

Envoyez-moi les résultats (même partiels). Les mesures de durée (essais 1, 2, 10, 11) décident s'il faut accélérer le chiffrement sur les téléphones lents (risque R4).
