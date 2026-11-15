#!/usr/bin/env bash
# Installe le SDK Flutter dans une session en ligne (Ubuntu) et prépare le
# projet. Idempotent : ne retélécharge pas si la bonne version est présente.
#
# Usage : bash tool/setup_cloud.sh [dossier_d_installation]
# Par défaut : /home/user/sdk/flutter
#
# Après exécution, ajouter au PATH :  export PATH="$FLUTTER_HOME/bin:$PATH"
set -euo pipefail

FLUTTER_VERSION="3.50.0"
FLUTTER_SHA256="6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

FLUTTER_HOME="${1:-/home/user/sdk/flutter}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

installed_version() {
  if [ -x "$FLUTTER_HOME/bin/flutter" ] && [ -f "$FLUTTER_HOME/version" ]; then
    cat "$FLUTTER_HOME/version"
  fi
}

if [ "$(installed_version)" = "$FLUTTER_VERSION" ]; then
  echo "Flutter $FLUTTER_VERSION déjà présent dans $FLUTTER_HOME"
else
  echo "Téléchargement de Flutter $FLUTTER_VERSION…"
  tmp="$(mktemp -d)"
  curl -sS -L -o "$tmp/flutter.tar.xz" "$FLUTTER_URL"
  echo "$FLUTTER_SHA256  $tmp/flutter.tar.xz" | sha256sum -c -
  rm -rf "$FLUTTER_HOME"
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  tar -xJf "$tmp/flutter.tar.xz" -C "$tmp"
  mv "$tmp/flutter" "$FLUTTER_HOME"
  rm -rf "$tmp"
  echo "Flutter installé dans $FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_HOME" >/dev/null 2>&1 || true
flutter --disable-analytics >/dev/null 2>&1 || true
flutter config --no-analytics --enable-native-assets >/dev/null 2>&1 || true

cd "$PROJECT_DIR"
flutter pub get
dart run build_runner build 2>&1 | tail -1
echo "Prêt : flutter analyze / flutter test peuvent être lancés."
