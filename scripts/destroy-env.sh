#!/usr/bin/env bash
set -euo pipefail
ENVIRONMENT="${1:-}"
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Usage: scripts/destroy-env.sh dev|prod" >&2
  exit 2
fi
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="$ROOT_DIR/envs/$ENVIRONMENT"

if [[ -z "${TF_VAR_app_secret:-}" ]]; then
  read -rsp "Secret applicatif NovaSphere (nécessaire pour charger la configuration Terraform) : " TF_VAR_app_secret
  echo
  export TF_VAR_app_secret
fi
if grep -q 'REPLACE_WITH_STATE_BUCKET' "$WORKDIR/backend.tf"; then
  echo "Backend S3 non configuré dans $WORKDIR/backend.tf" >&2
  exit 1
fi
read -r -p "Cette opération va détruire toutes les ressources NovaSphere $ENVIRONMENT. Tapez '$ENVIRONMENT' pour continuer : " CONFIRM
if [[ "$CONFIRM" != "$ENVIRONMENT" ]]; then
  echo "Annulé."
  exit 1
fi
terraform -chdir="$WORKDIR" init -input=false
terraform -chdir="$WORKDIR" plan -destroy -input=false -out=destroy.tfplan
terraform -chdir="$WORKDIR" show destroy.tfplan
read -r -p "Relisez le plan. Tapez 'DESTROY-$ENVIRONMENT' pour appliquer : " FINAL
if [[ "$FINAL" != "DESTROY-$ENVIRONMENT" ]]; then
  rm -f "$WORKDIR/destroy.tfplan"
  echo "Annulé ; aucun apply exécuté."
  exit 1
fi
terraform -chdir="$WORKDIR" apply -input=false destroy.tfplan
rm -f "$WORKDIR/destroy.tfplan"
echo "Environnement $ENVIRONMENT détruit. Le bucket du backend S3 est conservé."
