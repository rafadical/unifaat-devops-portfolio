#!/usr/bin/env bash
# Rollback por tag: baixa uma versão publicada no ECR e a coloca no ar.
#
# Uso:   ./ecr-rollback.sh 1.0.0      (ou sha-abc1234, latest...)
set -euo pipefail

TAG="${1:?Informe a tag. Ex.: ./ecr-rollback.sh 1.0.0}"
REGION="${AWS_REGION:-us-east-1}"
REPO="${ECR_REPO:-technova-api}"
PORT="${PORT:-3000}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
IMAGE="$REGISTRY/$REPO:$TAG"

echo "==> Login no ECR..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

echo "==> Removendo cópia local para forçar o pull do registry..."
docker rmi -f "$IMAGE" >/dev/null 2>&1 || true

echo "==> Pull de $IMAGE..."
docker pull "$IMAGE"

echo "==> Substituindo o container technova-api..."
docker rm -f technova-api >/dev/null 2>&1 || true
docker run -d --name technova-api -p "$PORT:3000" -e GIT_SHA="$TAG" "$IMAGE"

for i in $(seq 1 15); do
  if curl -fsS "http://localhost:$PORT/health" >/dev/null; then
    echo "==> Rollback concluído: $IMAGE no ar"
    curl -s "http://localhost:$PORT/version"; echo
    exit 0
  fi
  sleep 2
done
echo "Health check falhou após o rollback" >&2
docker logs technova-api >&2
exit 1
