 # DocuSafe

Coffre-fort documentaire pour téléphone, développé avec Flutter. Les documents restent sur l'appareil, chiffrés, et l'application fonctionne sans connexion Internet.

Android en priorité (MVP), puis iPhone avec le même code.

> **Attention – 13/11/2026 :** le PC de développement est infecté par un virus. Flutter ne peut pas fonctionner tant que le PC n'est pas nettoyé. Voir [docs/problemes-connus.md](docs/problemes-connus.md).

## État d'avancement

| Phase | Contenu | État |
|---|---|---|
| 1 – Analyse et conception | Architecture, modèle de données, parcours, règles de sécurité | Validée le 13/11/2026 |
| 2 – Design | Système de design, maquettes, navigation | Terminée le 13/11/2026, **en attente de validation** |
| 3 – Socle | Projet Flutter, chiffrement, base de données, authentification | **Bloquée** : PC à nettoyer, puis Flutter à réinstaller |
| 4 – Fonctionnel | Scanner, importation, documents, recherche, échéances, paramètres | À venir |
| 5 – Sécurité et optimisation | Tests, corrections, optimisation | À venir |
| 6 – Publication | Builds, fiches des magasins, documents légaux | À venir |

## Voir les maquettes

Ouvrir `docs\maquettes\index.html` dans un navigateur, ou dans le terminal :

```powershell
start docs\maquettes\index.html
```

## Documentation

| Document | Contenu |
|---|---|
| [docs/cahier-des-charges.md](docs/cahier-des-charges.md) | Cahier des charges de référence (version 1.1) |
| [docs/01-analyse.md](docs/01-analyse.md) | Analyse, choix retenus, risques |
| [docs/02-architecture.md](docs/02-architecture.md) | Organisation du code, modules, navigation |
| [docs/03-modele-de-donnees.md](docs/03-modele-de-donnees.md) | Tables, relations, fichiers sur le téléphone |
| [docs/04-securite.md](docs/04-securite.md) | Règles de sécurité, analyse des risques, limites |
| [docs/05-parcours-utilisateurs.md](docs/05-parcours-utilisateurs.md) | Parcours de l'utilisateur, écran par écran |
| [docs/06-dependances.md](docs/06-dependances.md) | Paquets retenus et justification |
| [docs/07-design.md](docs/07-design.md) | Système de design : couleurs, typographie, composants, navigation |
| [docs/maquettes/index.html](docs/maquettes/index.html) | Maquettes des 46 écrans, en clair et en sombre |
| [docs/guide-installation-windows.md](docs/guide-installation-windows.md) | Installation de l'environnement de développement |
| [docs/problemes-connus.md](docs/problemes-connus.md) | Problèmes connus |

## Démarrer

Le projet Flutter sera créé en phase 3, une fois le PC nettoyé et Flutter réinstallé (voir [docs/problemes-connus.md](docs/problemes-connus.md)).
