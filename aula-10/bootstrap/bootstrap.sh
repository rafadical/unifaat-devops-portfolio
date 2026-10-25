#!/usr/bin/env bash
# Cria o bucket do remote state (se ainda não existir) e aplica as proteções via Terraform.
set -euo pipefail
REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="6322006-technova-aula10-tfstate-${ACCOUNT_ID}"

if ! aws s3api head-bucket --bucket "$BUCKET" --expected-bucket-owner "$ACCOUNT_ID" 2>/dev/null; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
fi

terraform init -input=false
terraform apply -input=false
echo "Bucket do state: $BUCKET (use como variável TF_STATE_BUCKET no GitHub)"
