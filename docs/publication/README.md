# Dossier de publication (phase 6)

Tout ce qu'il faut pour publier DocSafe sur Google Play, puis sur l'App Store. **Le travail s'arrête volontairement à une marche de la publication** (demande du développeur, 15/11/2026) : rien n'est envoyé à un magasin, aucun compte n'est créé ; l'envoi final reste une décision du développeur. Les étapes marquées **(vous)** demandent votre téléphone, vos comptes ou une décision de votre part ; le reste est prêt.

## Contenu du dossier

| Fichier | Contenu |
|---|---|
| [plan-essais-telephones.md](plan-essais-telephones.md) | Essais à faire sur de vrais téléphones Android, avec les résultats attendus |
| [signature.md](signature.md) | Créer la clé d'envoi Google Play sur une machine saine, la confier à GitHub, compiler le fichier à envoyer |
| [play-store.md](play-store.md) | Fiche Google Play, réponses aux questionnaires (sécurité des données, classification, public cible…) |
| [app-store.md](app-store.md) | Fiche App Store, confidentialité, chiffrement, étapes iPhone |
| [politique-confidentialite.html](politique-confidentialite.html) | Politique de confidentialité à mettre en ligne (adresse exigée par les deux magasins) |
| `images/` | Icône 512 × 512 et bannière 1024 × 500 pour Google Play |
| `captures/android/`, `captures/ios/` | Huit captures par plateforme, aux tailles exigées |

## Ce qui est automatique (GitHub)

| Recette | Quand | Ce qu'elle fait |
|---|---|---|
| Aperçu Android | À chaque envoi de code | APK de test, essai sur un téléphone simulé, contrôles de publication (pour information) |
| Publication Android | À la demande, ou quand la configuration Android change | Fichier AAB pour Google Play et APK de contrôle, avec l'identifiant définitif `com.docusafe.app` ; **contrôles bloquants** : aucune permission réseau, sauvegarde du système désactivée, application non déboguable, compatibilité avec les pages mémoire de 16 Ko |
| Compilation iOS | À la demande, ou quand la configuration iPhone change | Compile l'application iPhone sur un Mac, sans signature (vérifie que le projet iOS est prêt). **Réussie le 15/11/2026** : 34,7 Mo, `com.docusafe.app`, iOS 15 minimum. |

## Étapes, dans l'ordre

### Google Play

1. **(vous)** Nettoyer le PC (P1), ou utiliser une autre machine saine.
2. **(vous)** Faire les essais du [plan d'essais](plan-essais-telephones.md) avec l'APK « aperçu ». Me signaler chaque problème (capture + modèle du téléphone + version d'Android).
3. Je corrige ; la recette « Aperçu » vérifie chaque correction.
4. **(vous)** Créer un compte développeur Google Play (frais unique de 25 dollars à la date de rédaction). Un compte **personnel** récent doit faire tourner un **test fermé** avec plusieurs testeurs pendant plusieurs jours avant de pouvoir publier pour tous (12 testeurs pendant 14 jours lors de la rédaction : **à vérifier** au moment de créer le compte, la règle évolue).
5. **(vous)** Créer la clé d'envoi et la confier à GitHub : [signature.md](signature.md).
6. **(vous)** Mettre en ligne la [politique de confidentialité](politique-confidentialite.html) et noter son adresse.
7. **(vous)** Créer l'application dans la Play Console, remplir la fiche avec [play-store.md](play-store.md), envoyer l'AAB en **test interne**, puis en test fermé.
8. Passage en production après le test fermé.

### App Store (ensuite)

Voir [app-store.md](app-store.md) : compte Apple Developer, compilation signée dans le cloud, TestFlight.

## Points à décider ou à vérifier par vous

| Point | Pourquoi |
|---|---|
| Adresse e-mail de contact publique | Obligatoire sur les deux fiches. Aucune adresse n'a été inventée. |
| Hébergement de la politique de confidentialité | Les magasins exigent une adresse web publique (Google Sites, page personnelle… le dépôt GitHub étant privé). |
| Nom « DocSafe » | D'autres produits portent un nom proche (risque R10) : vérification des marques avant publication. |
| Chiffrement et réglementation | DocSafe contient du chiffrement. La France encadre la fourniture de moyens de cryptologie et Apple pose des questions d'export : **à vérifier** auprès des sources officielles (ANSSI, documentation d'App Store Connect) avant la publication. Ce point est juridique, pas technique. |
| Public cible | Proposé : 18 ans et plus (documents administratifs). À confirmer. |
| Version 1.0.0 | Déjà en place (`pubspec.yaml`). Le numéro de compilation est celui de la recette GitHub ; il augmente à chaque compilation, comme Google Play et Apple l'exigent. |
