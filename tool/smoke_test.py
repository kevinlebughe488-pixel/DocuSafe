#!/usr/bin/env python3
"""Test de fumée de la version aperçu sur un émulateur Android (GitHub Actions).

Installe l'APK, lance l'application, crée un coffre comme le ferait une
personne (en touchant les éléments repérés par leur texte d'accessibilité),
puis écrit dans le journal ce qui est affiché et les messages de
l'application. Utilisé par .github/workflows/apercu-android.yml.

Usage : python3 tool/smoke_test.py <chemin de l'APK> <dossier de sortie>
"""

import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

PACKAGE = "com.docusafe.app.apercu"
PIN = "204915"


def adb(*args, check=True, capture=True):
    return subprocess.run(
        ["adb", *args], check=check, capture_output=capture, text=True
    ).stdout


def nodes():
    """Éléments affichés : (libellé, centre x, centre y)."""
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml", check=False)
    xml = adb("shell", "cat", "/sdcard/ui.xml", check=False)
    start = xml.find("<?xml")
    if start < 0:
        return []
    try:
        root = ET.fromstring(xml[start:])
    except ET.ParseError:
        return []
    found = []
    for n in root.iter("node"):
        label = (n.get("content-desc") or n.get("text") or "").strip()
        bounds = re.findall(r"\d+", n.get("bounds", ""))
        if label and len(bounds) == 4:
            x1, y1, x2, y2 = map(int, bounds)
            found.append((label, (x1 + x2) // 2, (y1 + y2) // 2))
    return found


def show(step):
    labels = [label.replace("\n", " ") for label, _, _ in nodes()]
    print(f"--- Écran ({step}) : {labels}", flush=True)
    return labels


def tap(label, timeout=30, exact=True):
    """Touche le premier élément dont le libellé correspond."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        for text, x, y in nodes():
            first_line = text.split("\n")[0]
            if (first_line == label) if exact else (label in text):
                adb("shell", "input", "tap", str(x), str(y))
                print(f"Touché : {label}", flush=True)
                time.sleep(0.6)
                return True
        time.sleep(1)
    show(f"introuvable : {label}")
    return False


def type_pin():
    for digit in PIN:
        if not tap(digit, timeout=15):
            return False
    return tap("Continuer", timeout=10)


def main():
    apk, out = sys.argv[1], Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    adb("install", "-r", apk)
    adb("logcat", "-c")
    adb("shell", "monkey", "-p", PACKAGE, "-c",
        "android.intent.category.LAUNCHER", "1")
    time.sleep(8)
    show("démarrage")

    ok = tap("Passer", timeout=30) and tap("Créer mon coffre-fort", timeout=20)
    show("après l'accueil")
    ok = ok and type_pin()
    show("après le choix du code")
    ok = ok and type_pin()

    # Création du coffre : Argon2id, base chiffrée. On observe 90 secondes.
    for i in range(9):
        time.sleep(10)
        labels = show(f"création, {10 * (i + 1)} s")
        if any("Plus tard" in l or "Accueil" in l or "Déverrouiller plus vite" in l
               for l in labels):
            print("Coffre créé : écran suivant atteint.", flush=True)
            break

    adb("shell", "screencap", "-p", "/sdcard/ecran.png", check=False)
    adb("pull", "/sdcard/ecran.png", str(out / "ecran.png"), check=False)
    log = adb("logcat", "-d", "-v", "time", check=False)
    (out / "logcat.txt").write_text(log)
    print("=== Journal de l'application (flutter, erreurs) ===")
    for line in log.splitlines():
        if ("flutter" in line or "docusafe" in line or " E/" in line
                or "AndroidRuntime" in line or "FATAL" in line):
            print(line)
    print("Parcours d'accueil terminé" if ok else "Parcours d'accueil interrompu")


if __name__ == "__main__":
    main()
