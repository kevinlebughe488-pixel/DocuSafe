# Fiche Google Play et questionnaires

Textes prêts à copier dans la Play Console. Les longueurs maximales de Google sont respectées.

## Fiche principale

**Nom de l'application** (30 caractères au plus) :

> DocuSafe – Coffre-fort privé

**Description courte** (80 caractères au plus) :

> Vos papiers importants chiffrés sur votre téléphone, sans compte ni Internet.

**Description complète** :

> DocuSafe garde vos documents importants dans un coffre-fort chiffré, uniquement sur votre téléphone : pièce d'identité, passeport, permis, diplômes, contrats, factures, ordonnances.
>
> **Vos documents ne quittent jamais votre téléphone**
> • Aucun compte, aucune inscription.
> • L'application n'a pas accès à Internet : elle ne peut rien envoyer.
> • Aucune publicité, aucun suivi.
>
> **Tout est chiffré**
> • Chaque document est chiffré dès son ajout (AES-256).
> • Le coffre s'ouvre avec votre code, votre empreinte ou votre visage.
> • Il se verrouille tout seul dès que vous quittez l'application.
> • Une clé de récupération vous permet de retrouver l'accès si vous oubliez votre code.
>
> **Simple au quotidien**
> • Numérisez un document avec l'appareil photo, ou importez un PDF ou une photo.
> • Rangez-le dans une catégorie : identité, études, travail, finances, logement, santé…
> • Retrouvez-le en quelques lettres, même sans accents.
> • Soyez prévenu avant l'expiration d'un passeport ou d'un titre de séjour.
>
> **Vous gardez la main**
> • Partagez ou exportez un document quand vous le décidez.
> • Créez une sauvegarde chiffrée et restaurez-la sur un nouveau téléphone.
>
> Important : sans votre code ni votre clé de récupération, personne ne peut ouvrir le coffre, pas même l'éditeur de DocuSafe. Notez votre clé de récupération et gardez-la en lieu sûr.

**Catégorie** : Productivité.

**Coordonnées** : adresse e-mail publique **à compléter par vous** (obligatoire). Site web facultatif.

**Politique de confidentialité** : adresse de la page mise en ligne ([politique-confidentialite.html](politique-confidentialite.html)).

**Éléments graphiques** :

| Élément | Fichier |
|---|---|
| Icône (512 × 512) | `images/icone-play-512.png` |
| Bannière (1024 × 500) | `images/banniere-play-1024x500.png` |
| Captures téléphone (1080 × 2160) | `captures/android/` dans cet ordre : 13-accueil-rempli, 14-documents, 15-fiche, 21-apercu-scan, 22-recherche, 23-echeances, 10-securite, 27-sauvegarde |

Les captures montrent des documents d'exemple créés pour l'occasion (aucune vraie donnée).

## Contenu de l'application (questionnaires)

### Sécurité des données

| Question | Réponse | Justification |
|---|---|---|
| L'application collecte-t-elle ou partage-t-elle des données utilisateur ? | **Non** | Les données restent sur le téléphone. Google ne considère pas comme « collectées » les données traitées seulement sur l'appareil. L'application n'a pas la permission Internet (contrôlé à chaque compilation par `tool/check_apk.py`). |
| Chiffrement en transit | Sans objet | Rien n'est transmis. |
| Suppression des données | Les données sont effaçables dans l'application (supprimer un document, ou Paramètres → Sécurité → Effacer le coffre) et disparaissent avec la désinstallation. | |

### Classification du contenu

Catégorie : « Toutes les autres applications » (utilitaire). Répondre **non** à toutes les questions : pas de violence, pas de contenu sexuel, pas de langage grossier, pas de substances, pas de jeux d'argent, pas d'échanges entre utilisateurs, pas de partage de position, pas d'achats numériques. Résultat attendu : tous publics (PEGI 3).

### Public cible

Proposé : **18 ans et plus** (documents administratifs). L'application ne s'adresse pas aux enfants. À confirmer par vous.

### Autres déclarations

| Question | Réponse |
|---|---|
| Annonces | Non |
| Accès à l'application | Toutes les fonctions sont accessibles sans identifiant : il suffit de créer un coffre avec un code au choix. |
| Application gouvernementale, financière, de santé | Non |
| Autorisations sensibles (alarmes exactes, accès à tous les fichiers, localisation…) | Aucune : alarmes inexactes, sélecteurs du système pour les fichiers. |
| Service au premier plan | Aucun |

## Permissions demandées par l'application

| Permission | Pourquoi |
|---|---|
| Appareil photo | Numériser un document, quand vous le demandez |
| Notifications | Rappels d'expiration |
| Biométrie | Déverrouillage par empreinte ou visage, si activé |
| Démarrage du téléphone | Reprogrammer les rappels après un redémarrage |

La liste réellement présente dans le fichier compilé est affichée par la recette « Publication Android » (`verifications.txt`).
