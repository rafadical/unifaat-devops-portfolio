# Runbook: Rollback de Deploy — TechNova API

## Quando usar

- O job `deploy` passou, mas a aplicação apresenta erros.
- O health check passou, mas uma funcionalidade está quebrada.
- Bug crítico detectado depois do deploy.

## Opção A — Rollback via Git (preferida)

Mantém o histórico e passa por lint, testes e health check de novo.

```bash
git revert <sha-do-commit-ruim>
git push origin main   # o cd.yml reconstrói e implanta a versão anterior
```

## Opção B — Rollback manual na EC2 (emergência)

1. **Identificar a última imagem estável no ECR**

   ```bash
   aws ecr describe-images --repository-name technova-api --region us-east-1 \
     --query 'sort_by(imageDetails,&imagePushedAt)[-5:].[imageTags[0],imagePushedAt]' \
     --output table
   git log --oneline -5   # mapear a tag sha-xxxxxxx ao commit
   ```

2. **Conectar na EC2**

   ```bash
   ssh -i ~/.ssh/technova-aula10 ec2-user@<EC2_HOST>
   ```

3. **Exportar as credenciais da sessão atual do Lab** (AWS Details → AWS CLI → Show), digitando-as só no terminal da EC2, nunca em arquivos versionados:

   ```bash
   export AWS_ACCESS_KEY_ID=...  AWS_SECRET_ACCESS_KEY=...  AWS_SESSION_TOKEN=...
   ```

4. **Login no ECR (antes do pull) e recriar o container com a tag estável**

   ```bash
   ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   REGISTRY="${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
   aws ecr get-login-password --region us-east-1 \
     | docker login --username AWS --password-stdin "$REGISTRY"

   TAG=sha-COMMIT_BOM
   docker pull "$REGISTRY/technova-api:$TAG"
   docker stop technova-api && docker rm technova-api
   docker run -d --name technova-api -p 3000:3000 \
     --restart unless-stopped -e NODE_ENV=production -e GIT_SHA="$TAG" \
     "$REGISTRY/technova-api:$TAG"
   ```

5. **Verificar**

   ```bash
   curl -s http://localhost:3000/health
   curl -s http://localhost:3000/version   # commit deve ser o da tag estável
   docker logs --tail 50 technova-api
   ```

6. **Depois do rollback**
   - Registrar o incidente: horário, versão ruim, versão restaurada, sintoma.
   - Abrir um PR com a correção. **Atenção:** o próximo push na main vai implantar de novo o que estiver na main; faça o `git revert` (opção A) para que a main corresponda ao que está rodando.

## Problemas comuns

| Sintoma | Causa | Ação |
|---|---|---|
| `no basic auth credentials` / `denied` no pull | Faltou o login no ECR ou o token expirou | Refazer o passo 4 |
| `ExpiredToken` | Credenciais do Lab expiraram | Pegar novas em AWS Details e exportar de novo |
| `manifest unknown` | Tag removida pelo lifecycle (mais de 10 imagens) | Escolher uma tag ainda listada no passo 1 |
| Container reinicia em loop | Erro na versão escolhida | `docker logs technova-api` e escolher uma tag anterior |
