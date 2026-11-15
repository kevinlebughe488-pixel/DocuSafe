#!/usr/bin/env python3
"""Test de fumée de la version aperçu sur un émulateur Android (GitHub Actions).

Installe l'APK, lance l'application, crée un coffre comme le ferait une
personne (en touchant les éléments repérés par leur texte d'accessibilité),
le verrouille, le rouvre avec le code, arrête et relance l'application,
puis écrit dans le journal les écrans traversés, les messages de
l'application et un verdict. Utilisé par .github/workflows/apercu-android.yml.

Usage : python3 tool/smoke_test.py <chemin de l'APK> <dossier de sortie>
"""

import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

PACKAGE = "com.docsafe.app.apercu"
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


SCREENS = []


def show(step):
    labels = [label.replace("\n", " ") for label, _, _ in nodes()]
    print(f"--- Écran ({step}) : {labels}", flush=True)
    SCREENS.append((step, labels))
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


def type_pin(submit=None):
    """Tape le code. Six chiffres sont validés tout seuls (depuis le
    15/11/2026) ; [submit] ne sert qu'à un ancien coffre (bouton)."""
    for digit in PIN:
        if not tap(digit, timeout=15):
            return False
    return tap(submit, timeout=10) if submit else True


def wait_for(texts, seconds, step):
    """Attend qu'un des textes apparaisse à l'écran. Retourne True si vu."""
    deadline = time.time() + seconds
    while time.time() < deadline:
        time.sleep(4)
        labels = show(step)
        if any(t in label for t in texts for label in labels):
            return True
    return False


def main():
    apk, out = sys.argv[1], Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    adb("install", "-r", apk)
    adb("logcat", "-c")
    adb("shell", "monkey", "-p", PACKAGE, "-c",
        "android.intent.category.LAUNCHER", "1")
    time.sleep(8)
    show("démarrage")

    # « Passer » mène directement au choix du code ; sinon, dernier écran.
    ok = tap("Passer", timeout=30)
    tap("Créer mon coffre-fort", timeout=5)
    show("après l'accueil")
    ok = ok and type_pin()
    show("après le choix du code")
    ok = ok and type_pin()

    # Création du coffre : Argon2id, base chiffrée (60 secondes au plus).
    created = wait_for(["Plus tard", "Votre coffre est vide"], 60, "création")
    if created:
        tap("Plus tard", timeout=3)  # proposition de la biométrie, si affichée
        created = wait_for(["Votre coffre est vide"], 20, "accueil")

    # Verrouiller, puis rouvrir avec le code : la serrure du code (stockage
    # sécurisé d'Android) et la base chiffrée sont relues pour de vrai.
    relocked = reopened = restarted = False
    if created:
        relocked = tap("Verrouiller", timeout=10) and wait_for(
            ["Coffre verrouillé"], 20, "verrouillé")
    if relocked:
        reopened = type_pin() and wait_for(
            ["Votre coffre est vide"], 40, "rouvert")
    if reopened:
        # Application arrêtée puis relancée : le coffre doit être verrouillé,
        # et le même code doit le rouvrir.
        adb("shell", "am", "force-stop", PACKAGE)
        adb("shell", "monkey", "-p", PACKAGE, "-c",
            "android.intent.category.LAUNCHER", "1")
        restarted = (wait_for(["Coffre verrouillé"], 30, "relancé")
                     and type_pin()
                     and wait_for(["Votre coffre est vide"], 40, "rouvert après relance"))

    adb("shell", "screencap", "-p", "/sdcard/ecran.png", check=False)
    adb("pull", "/sdcard/ecran.png", str(out / "ecran.png"), check=False)
    log = adb("logcat", "-d", "-v", "time", check=False)
    (out / "logcat.txt").write_text(log)

    # Résumé compact, en toute fin de journal : messages de l'application
    # seule (processus de l'application, étiquette flutter), puis les écrans.
    pid = adb("shell", "pidof", PACKAGE, check=False).strip()
    own = [
        line for line in log.splitlines()
        if "flutter" in line or "docusafe" in line.lower()
        or "FATAL" in line or "E/AndroidRuntime" in line
        or (pid and f"({pid.rjust(5)})" in line and (" E/" in line or " W/" in line))
    ]
    print(f"=== Journal de l'application (pid {pid or 'absent'}, "
          f"{len(own)} lignes, 120 dernières) ===")
    for line in own[-120:]:
        print(line[:300])
    print("=== Écrans traversés ===")
    for step, labels in SCREENS:
        print(f"[{step}] {' | '.join(labels)[:400]}")
    errors = [line for line in log.splitlines() if "[docusafe] ERREUR" in line]
    # Composants créés par réflexion que R8 aurait abîmés (ML Kit : sans eux,
    # le scanner passe directement en mode de secours).
    app_pids = set(re.findall(r"Start proc (\d+):" + re.escape(PACKAGE) + r"[/ ]", log))
    if pid:
        app_pids.add(pid)
    broken = [
        line for line in log.splitlines()
        if "Could not instantiate" in line
        and any(f"({p.rjust(5)})" in line for p in app_pids)
    ]
    for line in broken:
        print(line[:300])
    steps = [
        ("saisie du code", ok),
        ("coffre créé", created),
        ("verrouillage", relocked),
        ("réouverture avec le code", reopened),
        ("réouverture après arrêt de l'application", restarted),
        (f"aucune erreur de l'application ({len(errors)} trouvée(s))", not errors),
        (f"composants ML Kit initialisés ({len(broken)} échec(s))", not broken),
    ]
    for name, passed in steps:
        print(f"=== {'RÉUSSI' if passed else 'ÉCHEC '} : {name}")
    success = all(passed for _, passed in steps)
    print(f"=== Verdict : {'TOUT RÉUSSI' if success else 'ÉCHEC'} ===", flush=True)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
