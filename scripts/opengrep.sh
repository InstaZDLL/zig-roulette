#!/usr/bin/env bash
# Lance l'analyse statique Opengrep en local, comme la CI.
#
#   ./scripts/opengrep.sh           # scan lisible dans le terminal
#   ./scripts/opengrep.sh --sarif   # génère aussi opengrep.sarif
#
# Installe Opengrep si besoin : https://opengrep.dev (ou via le script officiel
#   curl -fsSL https://raw.githubusercontent.com/opengrep/opengrep/main/install.sh | bash)
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v opengrep >/dev/null 2>&1; then
  echo "opengrep introuvable. Installez-le : https://opengrep.dev" >&2
  exit 127
fi

args=(scan --config auto --config .opengrep/rules)
if [[ "${1:-}" == "--sarif" ]]; then
  args+=(--sarif --output opengrep.sarif)
  echo "Rapport SARIF -> opengrep.sarif"
fi

exec opengrep "${args[@]}" .
