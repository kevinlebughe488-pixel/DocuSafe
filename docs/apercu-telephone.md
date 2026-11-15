# Voir l'application sur un téléphone Android

À chaque envoi de code sur GitHub, GitHub compile l'application tout seul et la publie. Vous n'avez rien à installer sur le PC : il suffit du téléphone.

## Comment ça marche

1. Un envoi de code sur GitHub (un « push ») lance la recette `.github/workflows/apercu-android.yml`.
2. GitHub vérifie le code (`flutter analyze`), lance les tests, puis compile l'**APK**. Un APK est le fichier d'installation d'une application Android.
3. L'APK est publié dans la page **Releases** du dépôt, sous l'étiquette **apercu**. Chaque nouvel envoi remplace la version précédente. Comptez 10 à 20 minutes.

Pour suivre la compilation : onglet **Actions** du dépôt sur GitHub. Une coche verte signifie que l'APK est prêt. Une croix rouge signifie qu'un test ou la compilation a échoué : rien n'est publié.

## Installer la première fois

1. Sur le téléphone, connectez-vous à GitHub : application **GitHub** ou navigateur. Le dépôt est privé, la connexion est donc nécessaire.
2. Ouvrez la page : `https://github.com/kevinlebughe488-pixel/DocuSafe/releases/tag/apercu`
3. Dans **Assets**, touchez le fichier `DocSafe-apercu-….apk` pour le télécharger.
4. Ouvrez le fichier téléchargé. Android demande d'autoriser l'installation depuis cette source (le navigateur ou l'application Fichiers) : acceptez **pour cette source seulement**.
5. Touchez **Installer**. L'application apparaît sous le nom **DocSafe aperçu**.

## Mettre à jour

Refaites les étapes 2 à 5. La nouvelle version s'installe **par-dessus** l'ancienne : votre coffre et vos documents de test sont conservés.

## À savoir

- **C'est une version de test.** Elle porte un identifiant différent (`com.docsafe.app.apercu`) et une clé de signature de test, enregistrée dans le dépôt (`android/app/apercu.keystore`). Cette clé a été créée dans la session en ligne, jamais sur le PC infecté. Elle ne servira **jamais** à la publication sur le Play Store : la vraie clé sera créée en phase 6, sur une machine saine.
- N'y mettez pas vos vrais documents tant que l'application est en développement : une version suivante pourrait demander de recréer le coffre.
- Google Play Protect peut afficher un avertissement (« application inconnue ») : c'est normal pour une application installée hors du Play Store. Choisissez « Installer quand même ».
- Ne transmettez pas l'APK à d'autres personnes.

## Sans téléphone Android : Appetize.io

Appetize.io est un site qui fait tourner un téléphone Android **dans le navigateur**. Rien à installer.

### Version automatique (recommandée) : un lien toujours à jour

Une fois réglé, chaque envoi de code met à jour **la même adresse** : vous ouvrez toujours le même lien et vous voyez la dernière version.

À faire **une seule fois**, depuis un appareil sain (téléphone, tablette, autre ordinateur ; pas le PC infecté) :

1. Sur https://appetize.io, créez un compte gratuit.
2. Dans votre compte Appetize, ouvrez la page des réglages et copiez votre **jeton d'API** (« API token » : un mot de passe réservé aux programmes).
3. Sur GitHub : dépôt DocuSafe → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**. Nom : `APPETIZE_API_TOKEN`. Valeur : le jeton copié.
4. Prévenez-moi : je relance une compilation.

Ensuite, le lien « **Essayer dans le navigateur** » apparaît en haut de la page de l'aperçu : https://github.com/kevinlebughe488-pixel/DocuSafe/releases/tag/apercu

### Version manuelle

1. Téléchargez l'APK depuis la page Releases (voir plus haut).
2. Sur https://appetize.io, envoyez l'APK (« Upload »).
3. Le site affiche un téléphone : utilisez l'application à la souris et au clavier.

### À savoir

- L'offre gratuite limite le temps d'utilisation chaque mois et chaque séance.
- Le scanner (caméra), l'empreinte et les notifications n'y fonctionnent pas. Créez le coffre avec un code, puis importez des documents depuis le téléphone simulé.
- Dans la version aperçu seulement, l'écran n'est pas protégé contre les captures : sinon le site n'afficherait qu'un écran noir. La version publiée garde la protection.
- Le lien Appetize est privé tant que vous ne le partagez pas, mais quiconque l'a peut essayer l'application. Elle ne contient aucune donnée : chaque visiteur part d'un coffre vide.
- **Tant que le PC est infecté** : ne vous connectez pas à GitHub ni à Appetize depuis ce PC, car le virus peut voler les mots de passe tapés. Utilisez un autre appareil : un autre ordinateur, une tablette, ou même un iPhone (le site marche dans Safari).

## Plus tard, sur le PC nettoyé

L'émulateur d'Android Studio (un téléphone Android simulé sur le PC) affichera l'application sans limite de temps : glissez l'APK sur la fenêtre de l'émulateur pour l'installer.

## iPhone

Impossible pour l'instant d'installer la version iPhone : il faut un compte développeur Apple et une compilation sur Mac, prévus en phase 6 (service Codemagic ou GitHub sur machine macOS).
