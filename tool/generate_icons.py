#!/usr/bin/env python3
"""Génère toutes les icônes de DocSafe à partir du symbole (phase 6).

Le dessin reprend exactement la géométrie de `lib/core/widgets/ds_logo.dart`
(docs/07-design.md §2) : document blanc à coin replié, serrure bleue, fond
bleu DocSafe #205DB0.

Produit :
- Android : icônes classiques (mipmap-*/ic_launcher.png, coins arrondis),
  icône adaptative (avant-plan, fond uni) et monochrome (icônes à thème
  d'Android 13) ;
- iOS : toutes les tailles de AppIcon.appiconset, carrées et opaques (iOS
  arrondit lui-même ; l'App Store refuse la transparence) ;
- Google Play : icône 512 × 512 et bannière 1024 × 500 (docs/publication/).

Usage : python3 tool/generate_icons.py   (depuis la racine du dépôt)
Nécessite Pillow. Relancer après toute modification du symbole.
"""

import json
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BRAND = (0x20, 0x5D, 0xB0, 255)
FOLD = (0xD7, 0xE2, 0xFF, 255)
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
SS = 4  # suréchantillonnage, pour des bords lisses

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
PUB = ROOT / "docs/publication/images"


def symbol(draw, cx, cy, s, monochrome=False):
    """Document et serrure, centrés en (cx, cy), à l'échelle s du logo."""
    def pt(x, y):
        return (cx + (x - 0.5) * s, cy + (y - 0.5) * s)

    doc = [pt(0.30, 0.20), pt(0.58, 0.20), pt(0.70, 0.32), pt(0.70, 0.80), pt(0.30, 0.80)]
    draw.polygon(doc, fill=WHITE)
    if not monochrome:
        draw.polygon([pt(0.58, 0.20), pt(0.58, 0.32), pt(0.70, 0.32)], fill=FOLD)
    else:
        # Monochrome : le coin replié devient une découpe.
        draw.polygon([pt(0.58, 0.20), pt(0.58, 0.32), pt(0.70, 0.32)], fill=CLEAR)
        draw.polygon([pt(0.58, 0.215), pt(0.58, 0.32), pt(0.685, 0.32)], fill=WHITE)
    ink = CLEAR if monochrome else BRAND
    # Anse : demi-cercle supérieur de rayon 0,08, trait 0,05, bouts arrondis.
    r, w = 0.08 * s, 0.05 * s
    acx, acy = pt(0.50, 0.49)
    bbox = [acx - r - w / 2, acy - r - w / 2, acx + r + w / 2, acy + r + w / 2]
    draw.arc(bbox, start=180, end=360, fill=ink, width=round(w))
    for ex in (acx - r, acx + r):
        draw.ellipse([ex - w / 2, acy - w / 2, ex + w / 2, acy + w / 2], fill=ink)
    # Corps de la serrure et trou de clé.
    bx0, by0 = pt(0.38, 0.51)
    bx1, by1 = pt(0.62, 0.69)
    draw.rounded_rectangle([bx0, by0, bx1, by1], radius=0.04 * s, fill=ink)
    kx, ky = pt(0.50, 0.60)
    kr = 0.03 * s
    draw.ellipse([kx - kr, ky - kr, kx + kr, ky + kr], fill=WHITE)


def render(size, background, rounded, scale, monochrome=False):
    """Image carrée : fond (ou transparente), symbole à l'échelle `scale`."""
    big = size * SS
    img = Image.new("RGBA", (big, big), CLEAR)
    d = ImageDraw.Draw(img)
    if background:
        if rounded:
            d.rounded_rectangle([0, 0, big - 1, big - 1], radius=0.22 * big, fill=BRAND)
        else:
            d.rectangle([0, 0, big, big], fill=BRAND)
    symbol(d, big / 2, big / 2, scale * big, monochrome=monochrome)
    return img.resize((size, size), Image.LANCZOS)


def save(img, path, opaque=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    if opaque:
        img = img.convert("RGB")
    img.save(path, optimize=True)


def android():
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, k in densities.items():
        # Icône classique (Android 7) : carré bleu arrondi, plein cadre.
        save(render(round(48 * k), True, True, 1.0), RES / f"mipmap-{name}/ic_launcher.png")
        # Icône adaptative : calque de 108 dp ; le symbole tient dans le
        # cercle de sécurité de 66 dp (hauteur du document : 48 % du calque).
        fg = round(108 * k)
        save(render(fg, False, False, 0.80), RES / f"mipmap-{name}/ic_launcher_foreground.png")
        save(render(fg, False, False, 0.80, monochrome=True),
             RES / f"mipmap-{name}/ic_launcher_monochrome.png")
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Généré par tool/generate_icons.py -->\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n'
    )
    (RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(adaptive)
    colors = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Généré par tool/generate_icons.py : fond de l\'icône adaptative. -->\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#205DB0</color>\n'
        '</resources>\n'
    )
    (RES / "values/ic_launcher_background.xml").write_text(colors)


def ios():
    contents = json.loads((IOS / "Contents.json").read_text())
    for image in contents["images"]:
        pts = float(image["size"].split("x")[0])
        px = round(pts * int(image["scale"].rstrip("x")))
        # Plein cadre, opaque, symbole un peu plus petit qu'Android (la grille
        # d'Apple laisse plus de marge).
        save(render(px, True, False, 0.86), IOS / image["filename"], opaque=True)


def play_store():
    save(render(512, True, False, 0.86), PUB / "icone-play-512.png", opaque=True)
    # Bannière (« feature graphic ») : 1024 × 500, sans transparence.
    w, h = 1024 * SS, 500 * SS
    img = Image.new("RGBA", (w, h), BRAND)
    d = ImageDraw.Draw(img)
    # Symbole posé directement sur le bleu, à gauche du nom.
    tile = 380 * SS
    tx = 60 * SS
    symbol(d, tx + tile / 2, h / 2, tile)
    fonts = Path(os.environ.get("FLUTTER_ROOT", "/home/user/sdk/flutter")) / \
        "bin/cache/artifacts/material_fonts"
    title = ImageFont.truetype(str(fonts / "Roboto-Bold.ttf"), 96 * SS)
    tagline = ImageFont.truetype(str(fonts / "Roboto-Regular.ttf"), 44 * SS)
    x = tx + tile + 20 * SS
    d.text((x, 150 * SS), "DocSafe", font=title, fill=WHITE)
    d.text((x, 280 * SS), "Vos documents, protégés.", font=tagline, fill=(0xD7, 0xE2, 0xFF, 255))
    save(img.resize((1024, 500), Image.LANCZOS), PUB / "banniere-play-1024x500.png", opaque=True)


if __name__ == "__main__":
    android()
    ios()
    play_store()
    print("Icônes générées.")
