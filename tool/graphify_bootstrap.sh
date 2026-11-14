#!/usr/bin/env bash
# Installe graphify s'il manque, puis met à jour le graphe du projet.
#
# Appelé au démarrage de chaque session Claude Code (hook SessionStart de
# .claude/settings.json), en ligne comme sur le PC. Réutilisable tel quel
# dans n'importe quel autre projet : copier ce fichier et le bloc
# « SessionStart » de .claude/settings.json.
#
# Ne bloque jamais la session : toute erreur est ignorée.
set -u
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/..}" 2>/dev/null || exit 0
export PATH="$HOME/.local/bin:$PATH"

if ! command -v graphify >/dev/null 2>&1; then
  if command -v uv >/dev/null 2>&1; then
    uv tool install graphifyy >/dev/null 2>&1 || true
  elif command -v pipx >/dev/null 2>&1; then
    pipx install graphifyy >/dev/null 2>&1 || true
  fi
fi
command -v graphify >/dev/null 2>&1 || exit 0

# Graphe du code, sans appel à une IA : quelques secondes.
graphify update . >/dev/null 2>&1 || true
exit 0
