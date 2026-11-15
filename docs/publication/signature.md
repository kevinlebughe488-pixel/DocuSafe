# Signature et fichier à envoyer à Google Play

## Principe

- Google Play signe lui-même l'application avec sa **clé de signature** (« Play App Signing », activé par défaut pour toute nouvelle application). Vous ne la voyez jamais.
- Vous, vous signez seulement le fichier que vous envoyez, avec une **clé d'envoi** (« upload key »). Si elle est perdue ou volée, Google peut la remplacer sur demande depuis la Play Console : c'est beaucoup moins grave que de perdre la clé de signature.
- **Ne jamais créer ni copier cette clé sur le PC infecté** (P1). Un virus pourrait la voler.

## 1. Créer la clé d'envoi (une seule fois, sur une machine saine)

Sur un PC Windows sain où Android Studio est installé, dans PowerShell :

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore "$env:USERPROFILE\docusafe-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

L'outil demande deux mots de passe et quelques renseignements (nom, ville, pays : ils ne sont pas publiés). Notez les mots de passe dans un **gestionnaire de mots de passe**.

Faites une **copie de sauvegarde** du fichier `docusafe-upload.jks` (clé USB rangée en lieu sûr, par exemple). Ne l'envoyez jamais par e-mail ni par messagerie, et ne l'ajoutez jamais au dépôt.

## 2. Confier la clé à GitHub

1. Transformer le fichier en texte (encodage « base64 ») et le copier dans le presse-papiers :

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\docusafe-upload.jks")) | Set-Clipboard
```

2. Sur GitHub : dépôt DocuSafe → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**. Créer quatre secrets :

| Nom du secret | Valeur |
|---|---|
| `DOCUSAFE_UPLOAD_KEYSTORE_BASE64` | Le texte copié à l'étape 1 |
| `DOCUSAFE_UPLOAD_STORE_PASSWORD` | Le mot de passe du fichier |
| `DOCUSAFE_UPLOAD_KEY_ALIAS` | `upload` |
| `DOCUSAFE_UPLOAD_KEY_PASSWORD` | Le mot de passe de la clé |

Les secrets ne sont jamais affichés, même dans les journaux de GitHub.

## 3. Compiler le fichier à envoyer

Sur GitHub : onglet **Actions** → **Publication Android** → **Run workflow**. Au bout d'environ 20 minutes, la page de la compilation propose le fichier `DocuSafe-publication-…` à télécharger. Il contient :

- `DocuSafe-…-cle-d-envoi.aab` : le fichier à envoyer dans la Play Console ;
- `DocuSafe-…-cle-d-envoi.apk` : la même application, installable directement pour un dernier contrôle ;
- `verifications.txt` : le résultat des contrôles (permissions, compatibilité).

Sans les secrets, les fichiers portent la mention `debogage` : ils servent aux vérifications mais Google Play les refuse.

## Plus tard, sur le PC nettoyé

Pour compiler sur le PC lui-même, créer le fichier `android/key.properties` (déjà exclu du dépôt) :

```
storeFile=C:\\Users\\VOTRE_NOM\\docusafe-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

puis, dans PowerShell, à la racine du projet :

```powershell
flutter build appbundle --release
```
