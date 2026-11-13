# Guide d'installation de l'environnement sur Windows

Document rédigé le 13/11/2026. Les commandes sont à lancer dans **PowerShell** ou dans le terminal de VS Code.

> **Avant de commencer : le PC doit être sain.** Le 13/11/2026, un virus actif a contaminé les programmes de Flutter juste après leur installation (voir [problemes-connus.md](problemes-connus.md)). Tant que le PC n'est pas nettoyé, suivre ce guide ne sert à rien : Flutter serait de nouveau bloqué. Après nettoyage, supprimer l'ancien dossier `D:\dev\flutter`, puis reprendre à l'étape 1.

---

## Ce qui est déjà en place sur ce PC

| Élément | État |
|---|---|
| VS Code + extensions Dart et Flutter | Installé |
| Git | Installé |
| Android Studio (avec Java intégré) | Installé |
| SDK Android : plateforme 37, build-tools, adb | Installé |

## Ce qu'il reste à faire

| Étape | Durée indicative |
|---|---|
| 0. Placer les caches sur le disque D: (facultatif, recommandé) | 1 min |
| 1. Installer Flutter | 10 à 20 min |
| 2. Ajouter les outils en ligne de commande Android et accepter les licences | 5 min |
| 3. Créer un émulateur | 10 à 15 min |
| 4. Préparer le téléphone Android | 5 min |
| 5. Vérifier | 2 min |

**À prévoir :** environ 6 à 8 Go de téléchargement au total (Flutter, image de l'émulateur, composants de compilation), et 15 à 20 Go d'espace disque.

---

## Étape 0 – Placer les caches sur D: (facultatif, recommandé)

Le disque C: n'a plus que 31 Go libres, alors que D: en a 213. Par défaut, les caches de compilation et l'émulateur s'installent sur C: et peuvent occuper plus de 10 Go.

À faire **avant** les étapes suivantes :

```powershell
[Environment]::SetEnvironmentVariable('PUB_CACHE', 'D:\dev\pub-cache', 'User')
[Environment]::SetEnvironmentVariable('GRADLE_USER_HOME', 'D:\dev\gradle', 'User')
[Environment]::SetEnvironmentVariable('ANDROID_AVD_HOME', 'D:\dev\avd', 'User')
```

| Variable | Ce qu'elle déplace |
|---|---|
| `PUB_CACHE` | Les paquets Dart et Flutter téléchargés |
| `GRADLE_USER_HOME` | Les composants de compilation Android |
| `ANDROID_AVD_HOME` | Les appareils virtuels de l'émulateur |

Fermez puis rouvrez VS Code et Android Studio pour que ces réglages soient pris en compte.

---

## Étape 1 – Installer Flutter

Emplacement recommandé : `D:\dev\flutter` (pas d'espace dans le chemin, pas besoin de droits administrateur, beaucoup d'espace libre).

### 1.1. Télécharger

```powershell
New-Item -ItemType Directory -Force D:\dev | Out-Null
git clone -b stable https://github.com/flutter/flutter.git D:\dev\flutter
```

Autre possibilité, sans Git : télécharger l'archive officielle
<https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.50.0-stable.zip>
et l'extraire dans `D:\dev` (le dossier `D:\dev\flutter\bin` doit exister à la fin).

### 1.2. Ajouter Flutter au PATH

```powershell
$chemin = [Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::SetEnvironmentVariable('Path', "$chemin;D:\dev\flutter\bin", 'User')
```

**Fermez complètement VS Code et tous les terminaux, puis rouvrez-les.** Sans cela, la commande `flutter` reste introuvable.

### 1.3. Vérifier

```powershell
flutter --version
```

Le premier lancement télécharge Dart : il dure quelques minutes. Résultat attendu : `Flutter 3.50.x • channel stable` et `Dart 3.14.x`.

---

## Étape 2 – Outils en ligne de commande Android et licences

1. Ouvrir **Android Studio**.
2. Sur l'écran d'accueil : **More Actions → SDK Manager**.
3. Onglet **SDK Tools**.
4. Cocher **Android SDK Command-line Tools (latest)**, puis **Apply**.
5. Dans PowerShell :

```powershell
flutter doctor --android-licenses
```

Répondre `y` à chaque question.

---

## Étape 3 – Créer un émulateur

1. Android Studio → **More Actions → Virtual Device Manager**.
2. **Create Virtual Device** → choisir un téléphone (par exemple « Medium Phone » ou un Pixel).
3. Image système : **API 36**, version marquée **Google Play**. C'est important : le scanner de documents a besoin des services Google Play.
4. **Finish**, puis démarrer l'émulateur avec le bouton ▶.

### Si l'émulateur refuse de démarrer

La virtualisation est bien activée dans le BIOS de ce PC, mais la fonction Windows correspondante ne l'est pas encore. Si un message parle d'« hypervisor » ou d'accélération matérielle, lancez PowerShell **en tant qu'administrateur** :

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All
```

Puis redémarrez le PC.

### Plus tard (phase 5)

Un second émulateur sera utile pour simuler un téléphone d'entrée de gamme : Android 7 ou 8, 2 Go de RAM, image **sans** Google Play. Il servira à tester la solution de repli du scanner.

---

## Étape 4 – Préparer le téléphone Android

1. **Paramètres → À propos du téléphone** : toucher 7 fois **Numéro de build**.
2. **Paramètres → Système → Options pour les développeurs** : activer **Débogage USB**.
3. Brancher le téléphone au PC et accepter la demande d'autorisation affichée sur le téléphone.
4. Vérifier :

```powershell
flutter devices
```

Le téléphone doit apparaître dans la liste.

Sur certains modèles (Xiaomi, Redmi, Poco notamment), il faut aussi activer **Installer via USB** dans les options pour les développeurs.

---

## Étape 5 – Vérification finale

```powershell
flutter doctor -v
```

| Ligne | Résultat attendu |
|---|---|
| Flutter | ✓ |
| Android toolchain | ✓ |
| Android Studio | ✓ |
| VS Code | ✓ |
| Connected device | ✓ (émulateur démarré ou téléphone branché) |
| Visual Studio – develop Windows apps | Peut rester en erreur : inutile pour Android |
| Chrome – develop for the web | Peut rester en erreur : inutile pour Android |

---

## Problèmes fréquents

| Message ou symptôme | Solution |
|---|---|
| `flutter` n'est pas reconnu | Fermer et rouvrir VS Code. Vérifier que `D:\dev\flutter\bin` figure dans le PATH. |
| `cmdline-tools component is missing` | Étape 2 |
| `Android license status unknown` | Étape 2 : `flutter doctor --android-licenses` |
| L'émulateur ne démarre pas | Étape 3, paragraphe « Si l'émulateur refuse de démarrer » |
| Téléphone affiché `unauthorized` | Débrancher, rebrancher, accepter la demande sur le téléphone |
| `Building with plugins requires symlink support` | Lancer `start ms-settings:developers` et activer le **Mode développeur** de Windows |
| La première compilation dure 10 à 20 minutes | Normal : téléchargement des composants. Les suivantes sont rapides. |
| La première compilation échoue sans connexion | Normal : elle a besoin d'Internet (voir [06-dependances.md](06-dependances.md)). L'application, elle, fonctionne hors ligne. |

---

## iOS

Aucune installation possible sur Windows. La compilation iOS se fera plus tard sur un Mac ou avec un service de build dans le cloud (par exemple Codemagic). Le guide correspondant sera rédigé en phase 6.

---

Ce guide sera complété en phase 3 avec les commandes du projet (`flutter pub get`, `flutter run`, `flutter test`).
