#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
if ! command -v checkov >/dev/null 2>&1; then
  echo "Checkov absent. Installer avec : python3 -m pip install --user checkov" >&2
  exit 127
fi
checkov --directory . --framework terraform --output cli
