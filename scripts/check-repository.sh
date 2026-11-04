#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
if git ls-files | grep -E '(^|/)(terraform\.tfstate|terraform\.tfvars|.*\.tfplan|.*\.pem|\.env)$'; then
  echo "Fichier sensible ou généré suivi par Git : corriger avant push." >&2
  exit 1
fi
if git grep -n -I -E 'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}' -- . ':!*.md'; then
  echo "Identifiant AWS détecté dans le dépôt : révoquer/rotater si réel." >&2
  exit 1
fi
echo "Contrôle de base du dépôt terminé. Le résultat ne remplace pas un secret scanner."
