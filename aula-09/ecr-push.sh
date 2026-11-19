#!/usr/bin/env bash
# Publica a technova-api no Amazon ECR (AWS Academy Learner Lab, us-east-1).
#
# Uso:   ./ecr-push.sh            (a partir de aula-09/)
# Tags:  sha-<commit curto> e latest sempre; 1.2.3, 1.2 e 1 quando o commit
#        atual tem uma git tag vX.Y.Z (ou VERSION=X.Y.Z no ambiente).
# Requer: AWS CLI com as credenciais da sessão do Lab, Docker e Git.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
REPO="${ECR_REPO:-technova-api}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/technova-api"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
ECR_URI="$REGISTRY/$REPO"
SHA_TAG="sha-$(git -C "$SCRIPT_DIR" rev-parse --short=7 HEAD)"

# Semver: VERSION explícita ou git tag vX.Y.Z apontando para o commit atual
VERSION="${VERSION:-}"
if [ -z "$VERSION" ]; then
  GIT_TAG=$(git -C "$SCRIPT_DIR" describe --exact-match --tags HEAD 2>/dev/null || true)
  if [[ "$GIT_TAG" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    VERSION="${GIT_TAG#v}"
  fi
fi

TAGS=("$SHA_TAG" "latest")
if [[ "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  TAGS+=("$VERSION" "$MAJOR.$MINOR" "$MAJOR")
fi

echo "==> [1/5] Garantindo o repositório ECR '$REPO' em $REGION (idempotente)..."
if ! aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1; then
  aws ecr create-repository \
    --repository-name "$REPO" \
    --region "$REGION" \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE >/dev/null
  echo "    repositório criado"
else
  echo "    repositório já existe"
fi

echo "==> [2/5] Lifecycle policy: expira untagged após 1 dia e mantém as 20 imagens mais recentes..."
aws ecr put-lifecycle-policy --repository-name "$REPO" --region "$REGION" \
  --lifecycle-policy-text '{
    "rules": [
      {"rulePriority": 1, "description": "Remove imagens sem tag",
       "selection": {"tagStatus": "untagged", "countType": "sinceImagePushed", "countUnit": "days", "countNumber": 1},
       "action": {"type": "expire"}},
      {"rulePriority": 2, "description": "Mantem as 20 mais recentes",
       "selection": {"tagStatus": "any", "countType": "imageCountMoreThan", "countNumber": 20},
       "action": {"type": "expire"}}
    ]}' >/dev/null

echo "==> [3/5] Login no ECR ($REGISTRY)..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

echo "==> [4/5] Build multi-stage..."
docker build -t "$REPO:local" "$APP_DIR"

echo "==> [5/5] Tag e push: ${TAGS[*]}"
for tag in "${TAGS[@]}"; do
  docker tag "$REPO:local" "$ECR_URI:$tag"
  docker push "$ECR_URI:$tag"
done

echo
echo "==> Pronto! Imagens publicadas:"
for tag in "${TAGS[@]}"; do
  echo "    $ECR_URI:$tag"
done
