# Problèmes connus

Ce document recense les problèmes qui bloquent ou gênent le projet. Il sera tenu à jour à chaque phase.

| N° | Problème | Gravité | État |
|---|---|---|---|
| P1 | Le PC de développement est infecté par un virus (« Expiro ») | **Bloquant** | Ouvert depuis le 13/11/2026 |
| P2 | Flutter est installé mais ne peut pas s'exécuter | Bloquant (conséquence de P1) | Ouvert depuis le 13/11/2026 |
| P3 | La session en ligne ne peut pas compiler d'APK Android | Gênant | Ouvert depuis le 13/11/2026 |
| P4 | Les phases 3 et 4 (lots a et b) n'ont jamais été lancées sur un téléphone | À traiter dès que P1 est résolu | Ouvert depuis le 13/11/2026 |
| P5 | Miniatures et lecture des PDF (PDFium), scanner du système (ML Kit, VisionKit) non vérifiés hors des tests | À vérifier au premier lancement | Ouvert depuis le 14/11/2026 |
| P6 | « Exporter mes données » limité à 200 Mo ; partage et « Enregistrer sous » non vérifiés sur téléphone | Limite connue | Ouvert depuis le 14/11/2026 |

---

## P1 – Virus « Expiro » sur le PC de développement

### Ce qui a été constaté le 13/11/2026

1. Microsoft Defender signale des fichiers infectés par **Virus:Win32/Expiro** et **Virus:Win64/Expiro** : 310 détections au total (134 le 31/10/2026, 134 le 10/11/2026, 40 le 13/11/2026), toutes sur le disque D:.
2. Pour 154 d'entre elles, Defender indique que **la mise en quarantaine a échoué**. Les menaces sont marquées « actives ».
3. Le SDK Flutter 3.50.0 a été téléchargé depuis le site officiel de Google. L'empreinte SHA-256 de l'archive correspondait à celle publiée par Google : **le téléchargement était sain**.
4. Moins de deux minutes après l'extraction dans `D:\dev\flutter`, 20 programmes du SDK étaient signalés comme infectés.
5. Vérification : ces programmes ont **grossi d'environ 580 Ko** par rapport à l'archive officielle, alors que leur date de modification n'a pas changé. Les fichiers non exécutables (par exemple `flutter_windows.dll`) sont restés identiques.

| Fichier | Taille d'origine | Taille sur le disque | Écart |
|---|---|---|---|
| `dart.exe` | 5 452 288 | 6 031 360 | + 579 072 |
| `dartaotruntime.exe` | 5 411 840 | 5 990 912 | + 579 072 |
| `dartvm.exe` | 42 589 184 | 43 170 304 | + 581 120 |
| `impellerc.exe` | 6 356 992 | 6 938 624 | + 581 632 |
| `gen_snapshot.exe` | 5 255 680 | 5 834 240 | + 578 560 |
| `mingit\cmd\git.exe` | 38 552 | 612 352 | + 573 800 |
| `flutter_windows.dll` | 46 605 312 | 46 605 312 | 0 |

6. Defender attribue ces modifications au programme `jetbrains-toolbox.exe`, qui démarre avec Windows. Il est probablement contaminé lui-même et sert de relais.

### Ce que cela signifie

- Un virus **actif** sur ce PC ajoute son code aux fichiers `.exe` qu'il trouve, y compris ceux qui viennent d'être créés. Ce n'est pas une fausse alerte : les fichiers ont réellement été modifiés.
- D'après la description de Microsoft, cette famille de virus peut aussi **voler des informations** (identifiants, mots de passe).
- Ce constat repose sur le rapport de Defender et sur la comparaison des tailles de fichiers. Un diagnostic complet demande une analyse antivirus approfondie.

### Conséquences pour le projet

| Sujet | Conséquence |
|---|---|
| Flutter | Inutilisable sur ce PC tant qu'il n'est pas nettoyé : ses programmes sont contaminés puis bloqués par Defender (problème P2) |
| Phase 3 et suivantes | **Bloquées** sur ce PC |
| Documents et maquettes du projet | **Non touchés** : ce sont des fichiers texte, pas des programmes |
| Clés de signature (phase 6) | Ne jamais en créer sur un PC infecté : elles pourraient être volées |

### Ce qu'il ne faut pas faire

- Ne pas désactiver Defender.
- Ne pas « autoriser » ou « restaurer » les fichiers signalés.
- Ne pas ajouter d'exclusion sur le dossier Flutter : cela laisserait tourner des programmes contaminés.

### Marche à suivre conseillée

1. **Mettre le projet à l'abri :** copier le dossier `DocSafe` sur une clé USB ou un espace en ligne. Ne copier aucun fichier `.exe`.
2. **Analyse hors ligne de Microsoft Defender :** Sécurité Windows → Protection contre les virus et menaces → Options d'analyse → Analyse Microsoft Defender hors ligne. Le PC redémarre et l'analyse dure environ 15 minutes.
3. Lancer ensuite une **analyse complète**, puis consulter l'historique de protection.
4. Si des détections reviennent, ce qui est fréquent avec ce type de virus : la solution fiable est de **réinstaller Windows** en effaçant les disques (C: et D:), puis de ne remettre que les fichiers personnels (documents, photos, code source), jamais d'anciens programmes.
5. **Changer les mots de passe importants** (messagerie, GitHub, Google…) depuis un autre appareil sain, par précaution.
6. Après nettoyage : **mettre Windows à jour**. La version installée (Windows 11, build 22000) ne reçoit plus de correctifs de sécurité.
7. Les clés USB et disques externes utilisés sur ce PC peuvent contenir des programmes contaminés : les analyser aussi.

### Reprise du projet

Une fois le PC sain : supprimer `D:\dev\flutter`, réinstaller Flutter (15 minutes, voir [guide-installation-windows.md](guide-installation-windows.md)), vérifier avec `flutter doctor -v`, puis commencer la phase 3.

---

## P3 – Pas de compilation Android dans la session en ligne

- La machine Ubuntu de la session en ligne accède à `storage.googleapis.com` (Flutter), `pub.dev`, GitHub et aux dépôts Maven publics, mais **pas à `dl.google.com`**. Or le SDK Android, le plugin Android Gradle et les bibliothèques Google y sont hébergés.
- Conséquence : `flutter analyze`, `flutter test` et la génération de code fonctionnent (c'est ainsi que la phase 3 a été écrite et testée), mais `flutter build apk` est impossible dans cette session.
- Solutions possibles : (a) élargir l'accès réseau de l'environnement de la session en ligne à `dl.google.com` et `maven.google.com` ; (b) compiler sur le PC une fois nettoyé ; (c) utiliser un service de build dans le cloud (Codemagic, GitHub Actions), prévu de toute façon pour iOS.

## P4 – Phase 3 jamais exécutée sur un téléphone

- Le socle a été validé par 49 tests automatiques (chiffrement, clés, base chiffrée, écrans) et par des captures d'écran rendues par Flutter (voir `docs/captures/`).
- Ce qui n'a pas pu être vérifié : la biométrie réelle (Keystore, `flutter_secure_storage`), le canal `FLAG_SECURE`, la vitesse d'Argon2id sur un téléphone d'entrée de gamme (réglage prévu : 0,5 à 1 s), le comportement en arrière-plan, et toute la partie iOS (marquée « à vérifier sur iOS »).
- À faire au premier lancement : `flutter doctor -v`, `flutter run`, créer un coffre, verrouiller/déverrouiller, mesurer le temps de vérification du code.

## P5 – PDF : miniatures et lecture à vérifier sur téléphone

- Les miniatures des images et tout le chemin d'importation sont couverts par les tests (fichiers de test réels). Le rendu des PDF (première page en miniature, lecteur plein écran) passe par le moteur PDFium du paquet `pdfrx`, qui n'a pas pu être exercé dans la session en ligne : les tests utilisent un service de miniatures « images seulement ».
- Si le rendu PDF échoue sur le téléphone, le document reste valide (sans miniature) et l'erreur est journalisée sans donnée sensible. À vérifier au premier lancement : miniature d'un PDF importé, ouverture d'un PDF de plusieurs pages, vitesse sur un PDF de 20 Mo.
- **Scanner (lot b)** : l'écran du système (ML Kit sur Android, VisionKit sur iOS, repli à recadrage manuel sans services Google Play) ne peut pas s'ouvrir hors d'un téléphone. Les tests utilisent un scanner simulé qui rend de vraies images ; l'aperçu, l'assemblage en PDF, l'enregistrement chiffré et l'effacement des images en clair sont couverts. À vérifier au premier lancement : scan d'une page puis de plusieurs, refus de la caméra (message affiché), dossier du scanner vide après le scan, téléphone sans services Google Play.
- La vitesse du chiffrement dans un isolate (Dart pur, sans accélération native) est aussi à mesurer sur un téléphone d'entrée de gamme ; le plan B est décrit dans `docs/06-dependances.md` §5.

## P6 – Export : limite de 200 Mo, à vérifier sur téléphone

- Le sélecteur « Enregistrer sous » du système (paquet `file_picker`) reçoit le contenu **en mémoire**. Pour ne pas saturer la mémoire d'un téléphone modeste, l'archive « Exporter mes données » est refusée au-delà de 200 Mo de documents, avec un message clair qui propose l'export document par document.
- Piste pour lever la limite : écrire l'archive directement dans le fichier choisi, par petits morceaux (petit code natif Android, et iOS « à vérifier »). À décider après les premiers essais sur téléphone.
- Les tests utilisent un service de partage simulé. À vérifier au premier lancement : feuille de partage (messagerie, e-mail), enregistrement dans « Téléchargements » et sur Google Drive, suppression de la copie partagée 10 minutes après ou au verrouillage.

## P2 – Flutter installé mais inutilisable

- Flutter 3.50.0 est extrait dans `D:\dev\flutter` et ce dossier a été ajouté au PATH de l'utilisateur.
- La commande `flutter` répond « Le système ne peut exécuter le programme spécifié » : Defender bloque `dart.exe`, contaminé (voir P1).
- Ce dossier doit être **supprimé et réinstallé** après le nettoyage du PC. Il ne faut pas tenter de le réparer.
