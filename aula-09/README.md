# Aula 09 — Docker Registry (Amazon ECR) e IA no CI/CD

[![CI + ECR — Aula 09](https://github.com/rafadical/unifaat-devops-portfolio/actions/workflows/ci-aula09.yml/badge.svg)](https://github.com/rafadical/unifaat-devops-portfolio/actions/workflows/ci-aula09.yml)
[![AI Code Review](https://github.com/rafadical/unifaat-devops-portfolio/actions/workflows/ai-review.yml/badge.svg)](https://github.com/rafadical/unifaat-devops-portfolio/actions/workflows/ai-review.yml)
[![Security Scan — Aula 09](https://github.com/rafadical/unifaat-devops-portfolio/actions/workflows/security-scan.yml/badge.svg)](https://github.com/rafadical/unifaat-devops-portfolio/actions/workflows/security-scan.yml)

**Aluno:** rafael nogueira maruca — **RA:** 6322006

Pipeline que verifica o código, publica a imagem da TechNova API no **Amazon ECR** (AWS Academy Learner Lab, `us-east-1`) e revisa cada Pull Request automaticamente, bloqueando o merge quando há problema CRITICAL.

## Estrutura

```
.github/                          # na RAIZ do repositório (o GitHub só executa daqui)
├── workflows/
│   ├── ci-aula09.yml             # lint → test → build/push ECR (ecr-push.sh) → pull de verificação; rollback por tag
│   ├── ai-review.yml             # AI review em todo PR + comentário + quality gate
│   └── security-scan.yml         # npm audit + Trivy (Dockerfile e imagem)
└── scripts/
    ├── ai-review.js              # motor de análise (16 padrões)
    └── ai-review.test.js         # 8 testes do motor (node --test)

aula-09/
├── ecr-push.sh                   # cria o repo ECR, lifecycle, login, build, push (sha, latest, semver)
├── ecr-rollback.sh               # pull de uma tag do ECR e troca do container
├── ia-cicd-analise.md            # análise pedida no TF
├── technova-api/                 # API + Dockerfile multi-stage + .dockerignore + testes Jest
├── evidencias/                   # trechos reais dos logs
└── screenshots/
```

## Como executar

### Publicar no ECR (fluxo principal, local)

Pré-requisitos: AWS CLI com as credenciais da sessão do Learner Lab (`aws sts get-caller-identity` funcionando), Docker e Git.

```bash
cd aula-09
./ecr-push.sh                    # publica sha-<commit> e latest

git tag v1.0.0 && git push origin v1.0.0
./ecr-push.sh                    # no commit com a tag: também 1.0.0, 1.0 e 1

aws ecr describe-images --repository-name technova-api --region us-east-1 \
  --query 'imageDetails[].imageTags' --output table
```

### Rollback por tag

```bash
./ecr-rollback.sh 1.0.0          # pull da 1.0.0 no ECR e troca do container
curl http://localhost:3000/health
```

No GitHub: Actions → **CI + ECR — Aula 09** → *Run workflow* com `rollback_tag = 1.0.0`.

### Pelo GitHub Actions

Secrets necessários (Settings → Secrets and variables → Actions): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` da sessão do Lab. Eles expiram quando o Lab reinicia.

- Push na `main` alterando `aula-09/` → build e push `sha-*` + `latest`.
- Push de tag `v*.*.*` → também as tags semver.

### AI review

Abra qualquer Pull Request para a `main`. O workflow **AI Code Review** comenta a tabela de achados por severidade (e atualiza o mesmo comentário nos pushes seguintes). Se houver CRITICAL, o check fica vermelho e o merge fica bloqueado.

Rodar o motor localmente:

```bash
node --test .github/scripts/ai-review.test.js
git diff origin/main...HEAD > pr.diff
DIFF_FILE=pr.diff node .github/scripts/ai-review.js --gate
```

## Evidências

Ver [`evidencias/`](evidencias/) e [`screenshots/`](screenshots/).
