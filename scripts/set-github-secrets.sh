#!/usr/bin/env bash
# Roda no Git Bash com gh CLI instalado e autenticado (gh auth login).
# Execute TODA VEZ que renovar as credenciais do Academy.
# Uso: bash scripts/set-github-secrets.sh

set -euo pipefail

REPO="emilymarc/togglemaster-fase3"

echo "Lendo credenciais de ~/.aws/credentials ..."
KEY_ID=$(grep -m1 'aws_access_key_id'     ~/.aws/credentials | awk '{print $3}')
SECRET=$(grep -m1 'aws_secret_access_key' ~/.aws/credentials | awk '{print $3}')
TOKEN=$(grep -m1  'aws_session_token'     ~/.aws/credentials | awk '{print $3}')

if [[ -z "$KEY_ID" || -z "$SECRET" || -z "$TOKEN" ]]; then
  echo "ERRO: uma ou mais credenciais nao encontradas em ~/.aws/credentials"
  exit 1
fi

gh secret set AWS_ACCESS_KEY_ID     --body "$KEY_ID" --repo "$REPO"
gh secret set AWS_SECRET_ACCESS_KEY --body "$SECRET" --repo "$REPO"
gh secret set AWS_SESSION_TOKEN     --body "$TOKEN"  --repo "$REPO"

echo "Secrets configurados com sucesso em $REPO"
echo "Lembre de rodar este script toda vez que o Academy renovar as credenciais (a cada ~4h)."
