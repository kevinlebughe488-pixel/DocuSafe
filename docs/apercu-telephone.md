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
3. Dans **Assets**, touchez le fichier `DocuSafe-apercu-….apk` pour le télécharger.
4. Ouvrez le fichier téléchargé. Android demande d'autoriser l'installation depuis cette source (le navigateur ou l'application Fichiers) : acceptez **pour cette source seulement**.
5. Touchez **Installer**. L'application apparaît sous le nom **DocuSafe aperçu**.

## Mettre à jour

Refaites les étapes 2 à 5. La nouvelle version s'installe **par-dessus** l'ancienne : votre coffre et vos documents de test sont conservés.

## À savoir

- **C'est une version de test.** Elle porte un identifiant différent (`com.docusafe.app.apercu`) et une clé de signature de test, enregistrée dans le dépôt (`android/app/apercu.keystore`). Cette clé a été créée dans la session en ligne, jamais sur le PC infecté. Elle ne servira **jamais** à la publication sur le Play Store : la vraie clé sera créée en phase 6, sur une machine saine.
- N'y mettez pas vos vrais documents tant que l'application est en développement : une version suivante pourrait demander de recréer le coffre.
- Google Play Protect peut afficher un avertissement (« application inconnue ») : c'est normal pour une application installée hors du Play Store. Choisissez « Installer quand même ».
- Ne transmettez pas l'APK à d'autres personnes.

## Sans téléphone Android

- **Appetize.io** : site qui fait tourner un téléphone Android dans le navigateur. Créez un compte gratuit, envoyez-y l'APK téléchargé depuis la page Releases, puis utilisez l'application à la souris. L'offre gratuite limite le temps d'utilisation par mois. Le scanner (caméra) et l'empreinte n'y fonctionnent pas.
- **iPhone** : impossible pour l'instant. Il faut un compte développeur Apple et une compilation sur Mac, prévus en phase 6 (service Codemagic ou GitHub sur machine macOS).
