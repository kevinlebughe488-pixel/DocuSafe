# Parcours utilisateurs

Document rédigé le 13/11/2026 (phase 1). Il décrit ce que fait l'utilisateur, étape par étape. L'apparence des écrans sera définie en phase 2.

Les numéros entre parenthèses renvoient à la liste des écrans du cahier des charges (§5.3).

---

## 1. Première ouverture : création du coffre

```
Splash (1) → Onboarding (2) → Création du PIN (3) → Biométrie, facultatif (3)
          → Tableau de bord vide (5), avec le rappel « Noter ma clé »
```

Parcours révisé le 14/11/2026 (D6 révisée) : la clé de récupération n'est plus une étape de l'inscription.

| Étape | Ce que voit l'utilisateur |
|---|---|
| Onboarding, 4 pages courtes | 1. Bienvenue dans DocuSafe. 2. Vos documents restent sur votre téléphone : pas de compte, pas d'Internet. 3. Tout est chiffré et protégé par votre code. 4. Confidentialité : lien vers la politique et les conditions. Bouton « Créer mon coffre-fort ». |
| Création du PIN | Saisie de 6 chiffres ou plus, puis confirmation. Un code trop simple est refusé avec une explication. Le coffre est créé dès la confirmation ; la clé de récupération est générée en silence. |
| Biométrie | Proposée seulement si le téléphone la permet : « Activer Face ID » / « Activer l'empreinte », ou « Plus tard ». |
| Fin | Tableau de bord vide avec deux actions bien visibles : « Scanner un document » et « Importer un fichier ». Un bandeau « Votre clé de récupération n'est pas encore notée… » avec le bouton « Noter ma clé » reste affiché tant que la clé n'a pas été notée. |
| Noter ma clé | La clé s'affiche une seule fois. Texte clair : « Sans votre code et sans cette clé, vos documents seront définitivement perdus. Personne ne pourra les récupérer. » Bouton « Copier ». Case à cocher « J'ai conservé ma clé en lieu sûr » obligatoire pour terminer. Le bandeau disparaît ensuite. |

Cas particuliers :

- **L'utilisateur quitte avant d'avoir confirmé son code :** rien n'est créé. Il recommencera au prochain lancement. S'il quitte pendant l'étape biométrie, le coffre existe et s'ouvre avec le code.
- **Pas de biométrie sur le téléphone :** l'étape n'apparaît pas.
- **Aucun compte, aucune connexion** à aucun moment.

---

## 2. Ouvertures suivantes : déverrouillage

```
Splash (1) → Déverrouillage (4) → dernier écran consulté, ou Tableau de bord (5)
```

- Biométrie activée : la fenêtre du système s'ouvre toute seule. En cas d'échec ou d'annulation, le clavier PIN est disponible.
- PIN faux : message, nombre d'essais restants. Après 5 échecs : attente affichée avec un décompte.
- **« Code oublié ? »** → saisie de la clé de récupération → choix d'un nouveau PIN → coffre ouvert.
- Biométrie modifiée sur le téléphone : message « Votre biométrie a changé. Saisissez votre code. » puis proposition de la réactiver.

---

## 3. Scanner un document

```
Scanner (8) → scanner du système → Prévisualisation (9) → Informations → Fiche du document (7)
```

| Étape | Détail |
|---|---|
| Écran Scanner | Bouton principal « Numériser ». Accès secondaire « Importer des photos ». |
| Scanner du système | Détection automatique des contours, correction de perspective, recadrage manuel, filtres de lisibilité, plusieurs pages. Sur un téléphone sans services Google Play : prise de photo puis recadrage manuel. |
| Prévisualisation | Les pages en grille. **Réorganiser** par glisser-déposer, **supprimer** une page, **ajouter** des pages, **tout recommencer**. |
| Informations | Nom (prérempli : « Scan du 13/11/2026 »), catégorie. Facultatif : type, date d'expiration, tags. |
| Enregistrement | Barre de progression : création du PDF, chiffrement. Puis ouverture de la fiche. |

Cas particuliers : annulation à tout moment (rien n'est conservé) ; permission de l'appareil photo refusée (explication et lien vers les réglages) ; espace de stockage insuffisant (message clair, rien n'est perdu tant que la prévisualisation est ouverte).

---

## 4. Importer un fichier

```
Importation (10) → sélecteur du système → Vérification → Informations → Liste (6)
```

| Étape | Détail |
|---|---|
| Choix de la source | « Fichiers » (PDF, images) ou « Galerie » (photos). Sélection multiple possible. |
| Vérification | Type réel du fichier, taille, lisibilité. Fichier non accepté : message précis (« Ce format n'est pas pris en charge »). Fichier déjà présent : « Ce document est déjà dans votre coffre. Importer quand même ? » |
| Informations | Nom (prérempli avec le nom du fichier), catégorie, champs facultatifs. Pour plusieurs fichiers : une catégorie commune, modifiable ensuite. |
| Fin | Rappel utile : « L'original se trouve toujours dans votre galerie ou vos fichiers. Supprimez-le si vous voulez le garder uniquement dans DocuSafe. » DocuSafe ne peut pas supprimer cet original à la place de l'utilisateur. |

**Depuis une autre application :** l'utilisateur choisit « Partager » puis « DocuSafe ». DocuSafe s'ouvre, demande le déverrouillage si nécessaire, puis reprend ce même parcours à l'étape « Vérification ».

---

## 5. Consulter un document

```
Liste (6) → Fiche (7) → Lecture
```

- **Liste :** filtre par catégorie, tri (date d'ajout, nom, date d'expiration), miniatures, pastille « expire bientôt ».
- **Fiche :** miniature, nom, type, catégorie, dates, description, tags, taille, nombre de pages. Actions : ouvrir, favori, modifier, partager, exporter, supprimer.
- **Lecture :** PDF (défilement, zoom, numéro de page) ou image (zoom). Le document est déchiffré à ce moment-là seulement, et son intégrité est vérifiée.
- **Document corrompu :** écran d'erreur dédié (21). Le contenu n'est pas affiché. Explication et proposition de supprimer la fiche.

Accès rapides : **Favoris (13)** et **Récents (14)**, ce dernier avec deux onglets, « Ajoutés récemment » et « Consultés récemment ».

---

## 6. Modifier un document

Depuis la fiche : renommer, changer la catégorie, le type, les dates, la description, les tags. Les tags déjà utilisés sont proposés pendant la saisie. Le favori se bascule d'un seul geste depuis la liste ou la fiche.

---

## 7. Rechercher

```
Barre de recherche (tableau de bord ou liste) → Recherche (12) → Fiche (7)
```

- Les résultats s'affichent pendant la saisie. Majuscules et accents sont ignorés.
- La recherche porte sur le nom, le type, la description, les tags, le nom du fichier et, plus tard, le texte reconnu par OCR.
- Filtres combinables : catégorie, tag, favoris, format, période d'ajout, période d'expiration.
- Aucun résultat : état vide avec un conseil (« Essayez un autre mot ou retirez un filtre »).

---

## 8. Gérer les catégories

```
Documents (6) → « Gérer les catégories » → Création / modification (11)
```

- **Ajouter ou modifier :** nom, icône (liste proposée), couleur (palette proposée).
- **Supprimer :** si la catégorie contient des documents, l'application demande « Où déplacer les N documents ? » (par défaut : « Autres »). Les documents ne sont jamais supprimés avec la catégorie.
- « Autres » ne peut pas être supprimée.
- **Déplacer un document :** depuis sa fiche, ou par sélection multiple dans la liste.

---

## 9. Échéances et rappels

```
Fiche (7) → date d'expiration → Gestion des rappels (16)        Onglet Échéances (15) → Fiche (7)
```

| Étape | Détail |
|---|---|
| Ajouter une date d'expiration | Sur la fiche ou à l'ajout du document. Quatre rappels sont créés : 90 jours, 30 jours, 7 jours avant, et le jour même. |
| Première date d'expiration | L'application explique à quoi servent les notifications, puis demande l'autorisation du système. En cas de refus, les échéances restent visibles dans l'onglet Échéances. |
| Gestion des rappels d'un document | Activer ou désactiver chaque rappel, ajouter un délai personnalisé. |
| Onglet Échéances | Trois groupes : « Expirés », « Dans les 30 jours », « Plus tard ». Chaque ligne indique le nombre de jours restants. |
| Notification | Texte générique par défaut. La toucher ouvre DocuSafe : déverrouillage, puis fiche du document. |

Réglages associés (Paramètres → Notifications) : activer ou désactiver tous les rappels, délais par défaut, heure d'envoi, affichage du nom du document.

---

## 10. Partager ou exporter

```
Fiche (7) → Partager / Exporter → Authentification → Avertissement → Feuille de partage ou choix du dossier
```

- **Avertissement :** « Le fichier partagé ne sera plus protégé par DocuSafe. » Boutons « Annuler » et « Continuer ».
- **Partager :** feuille de partage du système (messagerie, e-mail…).
- **Exporter :** enregistrement d'une copie à l'emplacement choisi. Un scan s'exporte en PDF ; une image importée s'exporte dans son format d'origine.
- Les fichiers temporaires sont supprimés automatiquement.

---

## 11. Supprimer un document

```
Fiche (7) → Supprimer → Confirmation de suppression (20) → Liste (6)
```

L'écran de confirmation affiche le nom du document et indique que la suppression est **définitive**. Le bouton de suppression est distinct et coloré en rouge ; « Annuler » est l'action par défaut.

---

## 12. Paramètres

| Section | Contenu |
|---|---|
| Profil local | Nom affiché sur le tableau de bord (facultatif, stocké uniquement sur le téléphone) |
| Sécurité (17) | Changer le PIN · Biométrie · Délai de verrouillage · Captures d'écran · Nouvelle clé de récupération · Verrouiller maintenant · Effacer le coffre |
| Notifications | Voir §9 |
| Stockage (19) | Espace occupé, nombre de documents, répartition par catégorie, nettoyage des fichiers temporaires |
| Exportation des données | Exporter tous les documents en clair vers un dossier choisi (authentification et avertissement) |
| Sauvegarde et synchronisation | Explication : les documents sont uniquement sur ce téléphone. Créer une sauvegarde chiffrée (fichier `.docusafe`, clé de récupération notée au préalable) ou en restaurer une (le contenu actuel est remplacé). La synchronisation est annoncée comme indisponible, sans bouton. Restauration aussi possible depuis l'accueil : « J'ai une sauvegarde » → fichier → clé de récupération → nouveau code. |
| Confidentialité, Conditions d'utilisation | Textes consultables hors ligne |
| À propos | Version, licences des composants |
| Assistance | Questions fréquentes hors ligne, adresse de contact |

---

## 13. Verrouillage automatique

- L'application passe en arrière-plan, ou reste 2 minutes sans action : le coffre se verrouille.
- Au retour : écran de déverrouillage, puis **retour à l'écran où l'utilisateur se trouvait**.
- Une saisie en cours (formulaire) est conservée si le retour est rapide. Elle est abandonnée si l'application a été fermée.

---

## 14. États vides et erreurs (21)

Chaque liste a un état vide qui explique quoi faire (« Aucun document pour l'instant. Scannez ou importez votre premier document. »).

Erreurs prévues, toujours avec un message clair et une action :

| Situation | Message et action |
|---|---|
| Espace de stockage insuffisant | Explication, bouton « Gérer le stockage » |
| Fichier illisible ou format refusé | Explication, retour au choix du fichier |
| Document corrompu | Le contenu n'est pas affiché, proposition de supprimer la fiche |
| Scanner indisponible | Bascule automatique sur la prise de photo avec recadrage manuel |
| Permission refusée | Explication, lien vers les réglages du téléphone |
| Erreur imprévue | Écran générique, bouton « Réessayer », aucune donnée technique sensible affichée |
