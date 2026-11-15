#!/usr/bin/env python3
"""Rapport de couverture des tests (cahier des charges §12).

Lit coverage/lcov.info (produit par `flutter test --coverage`) et écrit un
résumé par dossier, en Markdown, sur la sortie standard. Le code généré
(*.g.dart, l10n/generated) est exclu : il n'est pas écrit à la main.

Usage :
  flutter test --coverage --exclude-tags screenshots
  python3 tool/coverage_report.py coverage/lcov.info > docs/rapport-couverture.md
"""

import sys
from collections import defaultdict
from datetime import date

GROUPS = [
    ("lib/core/security/", "Sécurité : chiffrement, clés, code, verrouillage"),
    ("lib/core/database/", "Base de données"),
    ("lib/core/documents/", "Documents : ajout, lecture, export, recherche"),
    ("lib/core/backup/", "Sauvegarde et restauration"),
    ("lib/core/reminders/", "Échéances et rappels"),
    ("lib/core/storage/", "Fichiers du coffre"),
    ("lib/core/platform/", "Services du téléphone (simulés dans les tests)"),
    ("lib/core/", "Autres éléments du cœur (utilitaires, composants)"),
    ("lib/features/", "Écrans"),
    ("lib/app/", "Application : thème, navigation"),
    ("lib/", "Démarrage"),
]


def excluded(path):
    return path.endswith(".g.dart") or "/generated/" in path


def main():
    found = defaultdict(int)
    hit = defaultdict(int)
    files = {}
    current = None
    for line in open(sys.argv[1], encoding="utf-8"):
        line = line.strip()
        if line.startswith("SF:"):
            current = line[3:]
            if current.startswith("/"):
                current = current[current.index("lib/"):] if "lib/" in current else current
            files[current] = [0, 0]
        elif line.startswith("DA:") and current and not excluded(current):
            _, count = line[3:].split(",")[:2]
            files[current][0] += 1
            if int(count) > 0:
                files[current][1] += 1
    for path, (lf, lh) in files.items():
        if excluded(path):
            continue
        for prefix, _ in GROUPS:
            if path.startswith(prefix):
                found[prefix] += lf
                hit[prefix] += lh
                break
    total_f = sum(found.values())
    total_h = sum(hit.values())

    def pct(h, f):
        return f"{100 * h / f:.0f} %" if f else "—"

    print("# Rapport de couverture des tests")
    print()
    print(f"Produit le {date.today().strftime('%d/%m/%Y')} par `tool/coverage_report.py` "
          "à partir de `flutter test --coverage --exclude-tags screenshots`.")
    print("La couverture est la part des lignes de code exécutées au moins une fois "
          "pendant les tests automatiques. Le code généré est exclu.")
    print()
    print(f"**Couverture totale : {pct(total_h, total_f)}** ({total_h} lignes sur {total_f}).")
    print()
    print("| Partie | Lignes couvertes | Couverture |")
    print("|---|---|---|")
    for prefix, label in GROUPS:
        if found[prefix]:
            print(f"| {label} (`{prefix}`) | {hit[prefix]} / {found[prefix]} | {pct(hit[prefix], found[prefix])} |")
    print()
    print("## Fichiers les moins couverts")
    print()
    print("Fichiers de plus de 30 lignes, couverture la plus faible d'abord. "
          "Les services du téléphone (scanner, sélecteurs, notifications, partage) ne "
          "peuvent s'exécuter que sur un vrai téléphone : ils sont remplacés par des "
          "versions simulées dans les tests et vérifiés par les essais sur téléphone.")
    print()
    print("| Fichier | Couverture |")
    print("|---|---|")
    ranked = sorted(
        ((lh / lf, p, lh, lf) for p, (lf, lh) in files.items() if not excluded(p) and lf > 30),
    )
    for ratio, path, lh, lf in ranked[:15]:
        print(f"| `{path}` | {pct(lh, lf)} ({lh}/{lf}) |")


if __name__ == "__main__":
    main()
