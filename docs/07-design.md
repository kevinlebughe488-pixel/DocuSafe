# Système de design de DocuSafe

Document rédigé le 13/11/2026 (phase 2). Il fixe les règles visuelles de l'application. Les maquettes qui les appliquent se trouvent dans [maquettes/index.html](maquettes/index.html).

**Pour voir les maquettes :** ouvrir le fichier `docs\maquettes\index.html` dans un navigateur, ou lancer dans le terminal :

```powershell
start docs\maquettes\index.html
```

La page contient 46 écrans, avec un bouton **Clair / Sombre**.

---

## 1. Principes

1. **Inspirer confiance.** Sobre, net, sans effet inutile. Aucun dégradé, aucune décoration.
2. **Montrer la protection sans inquiéter.** Un seul signe discret, toujours le même : un cadenas sarcelle et les mots « Chiffré sur cet appareil ».
3. **Une action principale par écran.** Elle est en bleu plein ; les autres sont plus discrètes.
4. **Lisible partout.** Petit écran, plein soleil, texte agrandi, mode sombre.
5. **Des mots simples.** L'utilisateur lit « code » et « chiffré », jamais « PIN », « AES » ou « clé dérivée ».

---

## 2. Identité

| Élément | Choix |
|---|---|
| Nom affiché | DocuSafe |
| Signature | « Vos documents, protégés. » |
| Symbole | Un document blanc à coin replié, percé d'une serrure, sur un carré bleu aux angles arrondis |
| Couleur de marque | Bleu DocuSafe `#205DB0` |
| Couleur d'accent | Sarcelle `#246867`, réservée à tout ce qui évoque la protection |

Le symbole est dessiné en vectoriel (`DsLogo`). Les icônes de l'application sont produites à partir de la même géométrie par `tool/generate_icons.py` (phase 6) : icônes Android classiques, icône adaptative et monochrome (Android 13), toutes les tailles iOS (carrées, opaques), icône 512 × 512 et bannière 1024 × 500 pour Google Play (`docs/publication/images/`).

### Ton des textes

| Règle | Exemple |
|---|---|
| Vouvoiement, phrases courtes | « Saisissez votre code » |
| Un verbe d'action sur chaque bouton | « Enregistrer dans le coffre », « Créer une sauvegarde » |
| Mots du quotidien | « code » (pas « PIN »), « chiffré » (pas « crypté »), « empreinte » (pas « biométrie ») |
| Une erreur dit ce qui se passe **et** quoi faire | « Il manque 12 Mo sur le téléphone… » + bouton « Gérer le stockage » |
| Jamais de point d'exclamation ni de message technique | — |
| Formats français | 14 févr. 2027 · 1,2 Mo · 09:00 |

---

## 3. Couleurs

Les couleurs ont été **calculées avec l'algorithme officiel de Material 3** (bibliothèque `material-color-utilities` de Google) à partir de deux teintes : un bleu pour la marque, une sarcelle pour l'accent. Les valeurs sont ensuite **figées** : l'application utilisera exactement ces codes, sans recalcul, pour que les maquettes et l'application soient identiques.

### 3.1. Rôles Material 3

| Rôle | Clair | Sombre | Usage |
|---|---|---|---|
| `primary` | `#205DB0` | `#ABC7FF` | Bouton principal, liens, élément sélectionné |
| `onPrimary` | `#FFFFFF` | `#002F66` | Texte sur `primary` |
| `primaryContainer` | `#D7E2FF` | `#00458F` | Bouton flottant, illustrations |
| `onPrimaryContainer` | `#00458F` | `#D7E2FF` | Texte et icône sur `primaryContainer` |
| `secondary` | `#565E71` | `#BEC6DC` | Éléments secondaires |
| `onSecondary` | `#FFFFFF` | `#283041` | |
| `secondaryContainer` | `#DAE2F9` | `#3E4759` | Bouton secondaire, puce sélectionnée, onglet actif de la barre du bas |
| `onSecondaryContainer` | `#3E4759` | `#DAE2F9` | |
| `tertiary` | `#246867` | `#91D2D0` | Mention « Chiffré », intégrité vérifiée |
| `onTertiary` | `#FFFFFF` | `#003736` | |
| `tertiaryContainer` | `#ADEEEC` | `#00504F` | Illustration de la biométrie, bandeau d'information de sécurité |
| `onTertiaryContainer` | `#00504F` | `#ADEEEC` | |
| `error` | `#BA1A1A` | `#FFB4AB` | Suppression, erreur |
| `onError` | `#FFFFFF` | `#690005` | |
| `errorContainer` | `#FFDAD6` | `#93000A` | Étiquette « Expiré » |
| `onErrorContainer` | `#93000A` | `#FFDAD6` | |
| `surface` | `#FAF9FE` | `#121317` | Fond des écrans |
| `onSurface` | `#1A1B1F` | `#E2E2E7` | Texte principal |
| `onSurfaceVariant` | `#434750` | `#C3C6D1` | Texte secondaire, icônes |
| `surfaceContainerLowest` | `#FFFFFF` | `#0D0E12` | |
| `surfaceContainerLow` | `#F4F3F8` | `#1A1B1F` | Cartes, feuilles du bas |
| `surfaceContainer` | `#EEEDF3` | `#1E2024` | Barre de navigation, cadre des aperçus |
| `surfaceContainerHigh` | `#E8E7ED` | `#282A2E` | Barre de recherche, touches du clavier, fenêtres |
| `surfaceContainerHighest` | `#E2E2E7` | `#333539` | Étiquettes neutres |
| `surfaceDim` | `#DAD9DF` | `#121317` | |
| `surfaceBright` | `#FAF9FE` | `#38393D` | |
| `outline` | `#747781` | `#8D909B` | Bord des champs |
| `outlineVariant` | `#C3C6D1` | `#434750` | Séparateurs, bord des puces |
| `inverseSurface` | `#2F3034` | `#E2E2E7` | Message bref en bas d'écran |
| `inverseOnSurface` | `#F1F0F6` | `#2F3034` | |
| `inversePrimary` | `#ABC7FF` | `#205DB0` | |
| `surfaceTint` | `#205DB0` | `#ABC7FF` | |

### 3.2. Couleurs d'état (ajoutées à Material 3)

| Rôle | Clair | Sombre | Usage |
|---|---|---|---|
| `warning` | `#865300` | `#FFB960` | Texte « Déjà dans votre coffre » |
| `warningContainer` | `#FFDDB8` | `#653E00` | Étiquette « J-7 », avertissement de la clé de récupération |
| `onWarningContainer` | `#2B1700` | `#FFDDB8` | |
| `success` | `#2F6B2E` | `#95D78C` | Fichier vérifié |
| `successContainer` | `#B0F3A6` | `#145218` | |
| `onSuccessContainer` | `#002203` | `#B0F3A6` | |

Pour les échéances, trois états seulement : **rouge** = expiré, **ambre** = dans les 30 jours, **neutre** = plus tard. La couleur n'est jamais seule : l'étiquette porte toujours un texte (« Expiré », « J-7 », « 3 mois »).

### 3.3. Palette des catégories

Douze couleurs au choix. Chaque couleur a un fond et une teinte d'icône, inversés en mode sombre.

| Clé | Nom | Référence | Fond (clair) | Icône (clair) |
|---|---|---|---|---|
| `blue` | Bleu | `#4977C2` | `#D7E2FF` | `#04458E` |
| `indigo` | Indigo | `#6D6EC4` | `#E1DFFF` | `#3B3D8F` |
| `purple` | Violet | `#8C67B1` | `#F0DBFF` | `#59367D` |
| `pink` | Rose | `#B15989` | `#FFD8E8` | `#772957` |
| `red` | Rouge | `#C45349` | `#FFDAD6` | `#84241E` |
| `orange` | Orange | `#B85F00` | `#FFDCC5` | `#703700` |
| `amber` | Ambre | `#9B6F00` | `#FFDEA7` | `#5E4200` |
| `green` | Vert | `#498445` | `#B2F3A8` | `#165219` |
| `teal` | Sarcelle | `#278482` | `#9CF1EF` | `#00504F` |
| `cyan` | Cyan | `#2280A1` | `#BDE9FF` | `#004D64` |
| `brown` | Brun | `#917157` | `#FFDCC1` | `#5C412A` |
| `slate` | Gris-bleu | `#707884` | `#DBE3F1` | `#3F4753` |

En mode sombre : le fond prend la valeur « Icône (clair) » et l'icône prend la valeur « Fond (clair) ». La colonne « Référence » est la valeur enregistrée en base (`categories.color`).

Catégories créées avec le coffre :

| Catégorie | Couleur | Icône |
|---|---|---|
| Identité | Bleu | `badge` |
| Éducation | Violet | `school` |
| Professionnel | Sarcelle | `work` |
| Finances | Vert | `account_balance_wallet` |
| Immobilier | Orange | `home_work` |
| Santé | Rose | `medical_services` |
| Autres | Gris-bleu | `folder` |

### 3.4. Contrastes mesurés

Norme visée : WCAG niveau AA (4,5 pour un texte, 3 pour un élément graphique). Toutes les associations utilisées passent, en clair comme en sombre.

| Association | Clair | Sombre |
|---|---|---|
| Texte principal sur fond (`onSurface` / `surface`) | 16,4 | 14,4 |
| Texte secondaire sur fond | 8,9 | 10,9 |
| Texte secondaire sur barre de recherche | 7,6 | 8,4 |
| Lien bleu sur fond (`primary` / `surface`) | 6,2 | 10,9 |
| Texte du bouton principal | 6,5 | 7,7 |
| Texte sur fond bleu clair, gris-bleu ou sarcelle | 7,2 | 7,2 |
| Étiquette « Expiré » | 7,2 | 7,2 |
| Étiquette d'avertissement | 13,3 | 7,3 |
| Bord des champs (`outline` / `surface`) | 4,3 | 5,8 |
| Icône de catégorie sur son fond (valeur la plus faible des 12) | 7,2 | 7,2 |

---

## 4. Typographie

**Police du système** : Roboto sur Android, San Francisco sur iPhone. Aucune police n'est embarquée. La taille suit le réglage d'accessibilité du téléphone.

Échelle Material 3, rôles utilisés :

| Rôle | Taille / interligne | Graisse | Usage |
|---|---|---|---|
| `headlineMedium` | 28 / 36 | normale | Nom de l'application au démarrage, grand chiffre (stockage) |
| `headlineSmall` | 24 / 32 | normale | Titre d'un écran d'étape, d'une fenêtre, nom du document |
| `titleLarge` | 22 / 28 | normale | Titre de la barre supérieure, état vide |
| `titleMedium` | 16 / 24 | moyenne | Titre de section |
| `titleSmall` | 14 / 20 | moyenne | Onglets, petits titres |
| `bodyLarge` | 16 / 24 | normale | Titre d'une ligne de liste, saisie, texte d'onboarding |
| `bodyMedium` | 14 / 20 | normale | Texte courant, seconde ligne d'une liste |
| `bodySmall` | 12 / 16 | normale | Aides sous les champs |
| `labelLarge` | 14 / 20 | moyenne | Boutons, puces |
| `labelMedium` | 12 / 16 | moyenne | Étiquettes d'état ; barre de navigation en 11, sans espacement des lettres (révision du 14/11/2026 : cinq libellés sur un écran de 360 points) |

La clé de récupération s'affiche en police à chasse fixe, pour distinguer chaque caractère.

---

## 5. Espacements, formes, relief

| Sujet | Règle |
|---|---|
| Grille | Multiples de 4 : 4, 8, 12, 16, 24, 32 |
| Marge latérale des écrans | 16 |
| Entre deux champs de formulaire | 24 |
| Zone tactile minimale | 48 × 48 |
| Hauteur d'une ligne de liste | 56 (une ligne) ou 72 (deux lignes) |

| Arrondi | Éléments |
|---|---|
| 4 | Champs de saisie |
| 8 | Puces, étiquettes d'état, miniatures |
| 12 | Icônes de catégorie, bandeaux |
| 16 | Cartes, bouton flottant |
| 28 | Fenêtres, feuilles du bas, barre de recherche |
| Complet | Boutons, touches du clavier, interrupteurs |

**Relief :** pas d'ombres portées sur les cartes. La profondeur est donnée par des nuances de fond (les cinq niveaux `surfaceContainer`). Seuls le bouton flottant, le message bref et le grand aperçu d'un document portent une ombre légère.

---

## 6. Icônes

- Style **arrondi**, trait fin. Dans les maquettes : Material Symbols Rounded. Dans l'application : les icônes intégrées à Flutter (`Icons.…_rounded`), sans paquet supplémentaire.
- Version **pleine** uniquement pour l'élément sélectionné (onglet actif, favori).
- Taille 24. Une icône seule, sans texte, porte toujours un libellé pour les lecteurs d'écran.

---

## 7. Composants réutilisables

### 7.1. Composants Material 3 utilisés tels quels

Ils sont configurés une seule fois dans le thème : `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `TextButton`, `FloatingActionButton`, `Card`, `ListTile`, `SearchBar`, `TextField` (bord tracé), `Switch.adaptive`, `Checkbox`, `TabBar`, `SegmentedButton`, `FilterChip`, `InputChip`, `AlertDialog.adaptive`, feuille du bas, `SnackBar`, `LinearProgressIndicator`, `NavigationBar`.

| Bouton | Quand |
|---|---|
| Plein, bleu | L'action principale de l'écran (une seule) |
| Teinté | Action secondaire importante (« Importer », « Annuler » avant une suppression) |
| Bord tracé | Alternative (« Recommencer », « Restaurer ») |
| Texte | Action discrète (« Passer », « Plus tard », « Code oublié ? ») |
| Plein, rouge | Action destructrice confirmée (« Supprimer définitivement ») |
| Grand (hauteur 56) | Bouton unique en bas d'un écran d'étape |

### 7.2. Composants propres à DocuSafe

| Composant | Rôle | Écrans |
|---|---|---|
| `DsNavigationBar` | Barre du bas à cinq onglets, Scanner mis en valeur | Les cinq onglets |
| `DocumentTile` | Ligne de document : miniature, nom, détails, élément de fin | Listes, recherche, échéances, tableau de bord |
| `DocumentThumbnail` | Miniature chiffrée, déchiffrée à l'affichage (4 tailles) | Partout |
| `DocumentCard` | Carte verticale avec grande miniature | Favoris du tableau de bord |
| `CategoryIcon` | Icône sur fond coloré (3 tailles) | Catégories, puces |
| `CategoryCard` | Catégorie avec son nombre de documents | Tableau de bord |
| `StatusBadge` | Étiquette d'état : expiré, bientôt, neutre, sécurité | Échéances, listes, fiche |
| `SecureLabel` | Cadenas + « Chiffré sur cet appareil » | Démarrage, tableau de bord, fiche, formulaire |
| `SectionHeader` | Titre de section + action « Tout voir » | Tableau de bord, importation |
| `KeyValueRow` | Ligne « libellé – valeur » | Fiche d'un document |
| `InfoBanner` | Bandeau : information, avertissement, erreur, sécurité | Clé de récupération, rappels, sauvegarde |
| `StateView` | État vide ou erreur : image, titre, explication, actions | Tous les états vides et écrans d'erreur |
| `IllustrationCircle` | Grande icône dans un cercle | Onboarding, états vides |
| `PinDots`, `PinKeypad` | Points de saisie et clavier du code | Création du coffre, déverrouillage, nouvelle authentification |
| `StepHeader` | « Étape 2 sur 3 » avec barre de progression | Création du coffre |
| `BottomActions` | Zone de boutons fixée en bas | Formulaires, confirmations |
| `ConfirmDialog` | Fenêtre de confirmation | Partage, suppression d'une catégorie |
| `ProgressDialog` | Opération longue avec étapes | Enregistrement, export, sauvegarde |
| `ReauthSheet` | Nouvelle authentification par code | Opérations sensibles |
| `TagInput` | Saisie de tags avec suggestions | Formulaires |
| `PageTile` | Page numérisée déplaçable | Prévisualisation du scan |
| `StorageBar` | Barre d'occupation par catégorie | Stockage |
| `SettingsTile` | Ligne de réglage, avec valeur ou interrupteur | Paramètres |

Règle : **aucun écran ne définit ses propres couleurs, tailles de texte ou arrondis.** Tout vient du thème et de ces composants.

---

## 8. Navigation

| Sujet | Règle |
|---|---|
| Barre du bas | Cinq onglets : Accueil, Documents, Scanner, Échéances, Paramètres. Visible uniquement sur ces cinq écrans. |
| Scanner | Au centre, sur une pastille bleue **en permanence** : identifiable d'un coup d'œil, comme le demande le cahier des charges |
| Écran de détail | Plein écran, flèche de retour en haut à gauche |
| Écran de saisie ou de confirmation | Plein écran, croix de fermeture, action à droite (« Enregistrer ») |
| Choix rapide, demande d'autorisation | Feuille du bas |
| Question bloquante | Fenêtre au centre |
| Documents | Trois onglets en haut : Tous, Favoris, Récents |
| Retour du système | Remonte d'un niveau. Depuis un onglet principal : retour à l'Accueil, puis sortie. |
| Verrouillage | L'écran de déverrouillage apparaît **sans animation**. Après déverrouillage, retour à l'écran quitté. |
| Notification touchée | Déverrouillage, puis fiche du document |

---

## 9. Animations

- Brèves et fonctionnelles : 150 à 200 ms pour un changement d'état, 300 ms pour un changement d'écran. Courbes standard de Material 3.
- Aucune animation décorative. Aucune attente imposée à l'utilisateur.
- Toute opération de plus d'une demi-seconde montre une progression.
- Si le téléphone est réglé sur « réduire les animations », elles sont supprimées.

---

## 10. Accessibilité

| Exigence | Réponse |
|---|---|
| Taille du texte du système | Aucune hauteur fixe autour d'un texte. Dans les formulaires, les champs sont l'un sous l'autre : rien n'est coupé avec un texte agrandi. À vérifier jusqu'à 200 % en phase 5. |
| Lecteurs d'écran | Libellé sur chaque icône seule, sur les miniatures (« Aperçu de Passeport »), sur les étiquettes (« Expire dans 7 jours ») |
| Contrastes | Mesurés, tous conformes au niveau AA (§3.4) |
| Zones tactiles | 48 × 48 au minimum, touches du clavier de 72 |
| Couleur seule | Jamais : chaque état a aussi un texte ou une icône |
| Compréhension | Phrases courtes, un seul message par écran |

---

## 11. Adaptation à l'iPhone

À vérifier sur iOS.

- Interrupteurs, fenêtres et indicateurs de chargement en version adaptative (`.adaptive`) : ils prennent l'aspect iOS.
- Police San Francisco appliquée automatiquement.
- Geste de retour par balayage depuis le bord gauche.
- Respect des zones réservées (encoche, barre d'accueil).
- La structure, les couleurs et les textes restent identiques à Android.

---

## 12. Passage à Flutter (phase 3)

| Élément du design | Dans le code |
|---|---|
| Couleurs Material 3 | Deux `ColorScheme` écrits avec les valeurs exactes du §3.1 (pas de calcul au lancement) |
| Couleurs d'état et palette des catégories | Une extension de thème (`ThemeExtension`) |
| Typographie | Thème de texte Material 3 par défaut, police du système |
| Formes, hauteurs, marges | Thèmes de composants (`filledButtonTheme`, `cardTheme`, `inputDecorationTheme`…) et un fichier de constantes |
| Composants du §7.2 | Dossier `lib/core/widgets/` |
| Mode clair ou sombre | Suit le réglage du téléphone |

Les maquettes HTML ne sont pas réutilisées dans l'application : elles servent de modèle. Leur fichier `tokens.css` contient les mêmes valeurs que ce document.

---

## 13. Choix à valider

| N° | Choix | Raison |
|---|---|---|
| M1 | Bleu `#205DB0` et accent sarcelle | Le bleu évoque la confiance et laisse le rouge et l'ambre libres pour les échéances. Le sarcelle distingue ce qui touche à la protection. |
| M2 | Scanner au centre, pastille bleue permanente | Exigence du cahier des charges (§5.2) |
| M3 | Onglets Tous / Favoris / Récents dans Documents | Trois espaces distincts (§3.11) sans alourdir la barre du bas |
| M4 | Le mot « code » à la place de « PIN » | Plus simple pour le grand public |
| M5 | Lecture d'un document toujours sur fond sombre | Met le document en valeur, repose les yeux |
| M6 | Symbole : document à serrure | Proposition. Icône définitive en phase 6. |
| M7 | Écran dédié pour confirmer une suppression | Demandé par le cahier des charges (écran n° 20) ; « Annuler » y est mis en avant |
| M8 | **Révision du 14/11/2026 :** la maquette 3b (clé de récupération) n'est plus une étape de la création du coffre. Elle devient l'écran « Noter ma clé », ouvert depuis un bandeau d'avertissement sur l'accueil et depuis Sécurité. L'étape biométrie passe de « 3 sur 3 » à « 2 sur 2 ». Sur iPhone, les mots « Face ID » et « Touch ID » remplacent « empreinte ». | Inscription plus légère (D6 révisée), sans retirer la porte de secours. Les captures réelles sont dans `captures/`. |

---

## 14. Écrans des maquettes

| Groupe | Écrans | Écrans du cahier des charges (§5.3) |
|---|---|---|
| 1. Démarrage et création du coffre | 8 | 1, 2, 3 |
| 2. Déverrouillage | 3 | 4 |
| 3. Accueil | 3 | 5 |
| 4. Documents | 7 | 6, 7, 13, 14, 20 |
| 5. Ajouter un document | 5 | 8, 9, 10 |
| 6. Recherche et catégories | 5 | 11, 12 |
| 7. Échéances et rappels | 3 | 15, 16 |
| 8. Partage et export | 2 | — (§3.12) |
| 9. Paramètres | 5 | 17, 18, 19 |
| 10. Erreurs et états vides | 5 | 21 |

Les maquettes ont été contrôlées dans un navigateur, en clair et en sombre. Sans connexion Internet, elles s'affichent avec la police du système au lieu de Roboto ; le reste est identique.
