#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
BUCKET="${1:?Usage: scripts/bootstrap-state.sh <nom-bucket-s3-globalement-unique>}"
REGION="us-east-1"
if [[ ! "$BUCKET" =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]]; then
  echo "Nom de bucket invalide : minuscules, chiffres ou tirets (3 à 63 caractères)." >&2
  exit 1
fi
aws sts get-caller-identity >/dev/null
if aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  echo "Bucket déjà accessible : $BUCKET"
else
  echo "Création du bucket $BUCKET dans $REGION..."
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" >/dev/null
fi
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
for backend in envs/dev/backend.tf envs/prod/backend.tf; do
  sed -i "s/REPLACE_WITH_STATE_BUCKET/${BUCKET}/g" "$backend"
done
echo "Backend initialisé. Les fichiers envs/*/backend.tf pointent vers $BUCKET."
echo "Clés distinctes : novasphere/dev/terraform.tfstate et novasphere/prod/terraform.tfstate."
echo "Vérifiez le bucket et les backends avant terraform init."
