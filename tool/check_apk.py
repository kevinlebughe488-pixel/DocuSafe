#!/usr/bin/env python3
"""Vérifications de publication d'un APK Android (phase 6).

Contrôle, sur le fichier réellement compilé :
1. les permissions : aucune permission réseau (INTERNET), liste complète
   affichée pour relecture (docs/04-securite.md §16) ;
2. le manifeste : sauvegarde du système désactivée, application non
   déboguable, versions Android minimale et ciblée ;
3. la compatibilité avec les pages mémoire de 16 Ko (exigée par Google Play
   pour les applications qui ciblent Android 15 et plus) : alignement des
   segments des bibliothèques natives 64 bits et, si elles sont stockées sans
   compression, de leur position dans l'archive.

Usage : python3 tool/check_apk.py <apk> <dossier build-tools Android>
Code de sortie 1 si une vérification échoue.
"""

import struct
import subprocess
import sys
import zipfile
from pathlib import Path

PAGE_16K = 16 * 1024
FORBIDDEN = {
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.MANAGE_EXTERNAL_STORAGE",
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.READ_CONTACTS",
    "android.permission.RECORD_AUDIO",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.USE_EXACT_ALARM",
}
MIN_TARGET_SDK = 35

failures = []


def check(ok, message):
    print(("  OK    " if ok else "  ÉCHEC ") + message)
    if not ok:
        failures.append(message)


def aapt2(build_tools, *args):
    return subprocess.run(
        [str(Path(build_tools) / "aapt2"), *args],
        check=True, capture_output=True, text=True,
    ).stdout


def elf_load_alignments(data):
    """Alignement des segments PT_LOAD d'une bibliothèque ELF 64 bits."""
    if data[:4] != b"\x7fELF" or data[4] != 2:
        return None  # pas un ELF 64 bits
    little = data[5] == 1
    end = "<" if little else ">"
    e_phoff = struct.unpack_from(end + "Q", data, 0x20)[0]
    e_phentsize, e_phnum = struct.unpack_from(end + "HH", data, 0x36)
    aligns = []
    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        p_type = struct.unpack_from(end + "I", data, off)[0]
        if p_type == 1:  # PT_LOAD
            aligns.append(struct.unpack_from(end + "Q", data, off + 48)[0])
    return aligns


def data_offset(apk_path, info):
    """Position des données d'une entrée dans l'archive (en-tête local)."""
    with open(apk_path, "rb") as f:
        f.seek(info.header_offset)
        header = f.read(30)
        name_len, extra_len = struct.unpack_from("<HH", header, 26)
        return info.header_offset + 30 + name_len + extra_len


def main():
    apk, build_tools = sys.argv[1], sys.argv[2]
    print(f"=== Vérifications de publication : {Path(apk).name} ===")

    print("Permissions :")
    perms = sorted(
        line.split("'")[1] if "'" in line else line.split(":", 1)[1].strip()
        for line in aapt2(build_tools, "dump", "permissions", apk).splitlines()
        if line.startswith("uses-permission")
    )
    for p in perms:
        print(f"        {p}")
    for p in sorted(FORBIDDEN):
        check(p not in perms, f"absente : {p}")

    print("Manifeste :")
    badging = aapt2(build_tools, "dump", "badging", apk)
    target = min_sdk = 0
    for line in badging.splitlines():
        if line.startswith("targetSdkVersion:"):
            target = int(line.split("'")[1])
        if line.startswith("sdkVersion:") or line.startswith("minSdkVersion:"):
            min_sdk = int(line.split("'")[1])
    check(target >= MIN_TARGET_SDK, f"version Android ciblée {target} (au moins {MIN_TARGET_SDK})")
    check(min_sdk == 24, f"version Android minimale {min_sdk} (24 attendue)")
    check("application-debuggable" not in badging, "application non déboguable")
    tree = aapt2(build_tools, "dump", "xmltree", "--file", "AndroidManifest.xml", apk)
    backup_lines = [l for l in tree.splitlines() if "allowBackup" in l]
    check(any("false" in l or "0x0" in l for l in backup_lines),
          "sauvegarde automatique du système désactivée (allowBackup=false)")

    print("Pages mémoire de 16 Ko (bibliothèques natives 64 bits) :")
    with zipfile.ZipFile(apk) as z:
        libs = [i for i in z.infolist()
                if i.filename.startswith(("lib/arm64-v8a/", "lib/x86_64/"))
                and i.filename.endswith(".so")]
        check(bool(libs), f"{len(libs)} bibliothèques 64 bits trouvées")
        for info in libs:
            aligns = elf_load_alignments(z.read(info.filename))
            ok = aligns is not None and all(a >= PAGE_16K for a in aligns)
            check(ok, f"{info.filename} : segments alignés sur "
                      f"{min(aligns) if aligns else '?'} octets")
            if info.compress_type == zipfile.ZIP_STORED:
                offset = data_offset(apk, info)
                check(offset % PAGE_16K == 0,
                      f"{info.filename} : position dans l'archive alignée sur 16 Ko")

    print()
    if failures:
        print(f"=== {len(failures)} vérification(s) en échec ===")
        sys.exit(1)
    print("=== Toutes les vérifications de publication réussissent ===")


if __name__ == "__main__":
    main()
