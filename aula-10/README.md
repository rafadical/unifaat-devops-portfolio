# Aula 10 — Terraform Automatizado (GitOps) e Pipeline CD

**Aluno:** rafael nogueira maruca — **RA:** 6322006

Infraestrutura da TechNova gerenciada por Pull Requests (plan no PR, apply no merge) e deploy contínuo da `technova-api` na EC2: lint → test → build → push no Amazon ECR → deploy Recreate via SSH → health check. Ambiente: AWS Academy Learner Lab, `us-east-1`.

## Estrutura

```
.github/workflows/            # na RAIZ do repositório (o GitHub só executa daqui)
├── terraform-plan.yml        # PR → plan comentado no PR
├── terraform-apply.yml       # merge na main → apply
└── cd.yml                    # lint → test → build/push ECR → deploy → health check

aula-10/
├── bootstrap/main.tf         # S3 + DynamoDB do remote state (aplicado uma vez, localmente)
├── terraform/                # VPC, subnet pública, SG, EC2 (Docker), Elastic IP, ECR
│   ├── provider.tf           # provider + backend "s3"
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── user-data.sh          # instala Docker na EC2
├── technova-api/             # API Node.js + Dockerfile multi-stage + testes Jest
├── gitops-cd-analise.md      # análise pedida no TF
├── docs/runbook-rollback.md  # procedimento de rollback
└── screenshots/              # evidências
```

## Como reproduzir

### 1. Credenciais do Lab e chave SSH (local)

```bash
aws sts get-caller-identity          # credenciais do Learner Lab carregadas
ssh-keygen -t ed25519 -f ~/.ssh/technova-aula10 -N "" -C "technova-aula10"
```

### 2. Bootstrap do state remoto (uma vez)

```bash
cd aula-10/bootstrap
./bootstrap.sh   # cria o bucket pela AWS CLI e aplica versionamento, criptografia e lock
```

> O bucket é criado pela CLI porque o recurso `aws_s3_bucket` do Terraform consulta Object Lock, operação negada pelo SCP do Learner Lab.

### 3. Secrets e variável no GitHub

**Settings → Secrets and variables → Actions**

| Tipo | Nome | Valor |
|---|---|---|
| Secret | `AWS_ACCESS_KEY_ID` | Credencial da sessão do Lab |
| Secret | `AWS_SECRET_ACCESS_KEY` | Credencial da sessão do Lab |
| Secret | `AWS_SESSION_TOKEN` | Token da sessão do Lab |
| Secret | `SSH_PUBLIC_KEY` | Conteúdo de `~/.ssh/technova-aula10.pub` |
| Secret | `EC2_SSH_KEY` | Conteúdo de `~/.ssh/technova-aula10` (chave privada) |
| Secret | `EC2_HOST` | Output `ec2_public_ip` (após o primeiro apply) |
| Variable | `TF_STATE_BUCKET` | Output `state_bucket` do bootstrap |

> As 3 credenciais do Lab expiram a cada sessão. Ao reabrir o Lab, atualize-as e reexecute o workflow que falhou com `ExpiredToken`.

### 4. Primeiro apply e primeiro deploy

1. Push na `main` → **Terraform Apply** cria VPC, SG, EC2, Elastic IP e ECR. Copie `ec2_public_ip` do log para o secret `EC2_HOST`.
2. Actions → **CD Pipeline — Aula 10** → *Run workflow* (ou um push em `aula-10/technova-api/`).
3. `curl http://<EC2_HOST>:3000/health` e `curl http://<EC2_HOST>:3000/version`.

### 5. Testar o GitOps com uma mudança real

```bash
git checkout -b feat/add-https-sg-rule
# adicionar em aula-10/terraform/main.tf:
#   resource "aws_security_group_rule" "allow_https" { type = "ingress", from_port = 443, to_port = 443,
#     protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], security_group_id = aws_security_group.technova_api.id }
git commit -am "feat(aula-10): libera HTTPS no security group da API"
git push -u origin feat/add-https-sg-rule
# abrir PR → conferir o comentário do plan → merge → conferir o apply
```

### 6. Proteções recomendadas na `main`

Settings → Branches → regra para `main`: exigir PR, exigir o check **Terraform Plan** e não permitir bypass.

### 7. Destruir ao final

```bash
cd aula-10/terraform
terraform init -backend-config="bucket=<state_bucket>"
terraform destroy -var="ssh_public_key=$(cat ~/.ssh/technova-aula10.pub)"
cd ../bootstrap && terraform destroy
```

## Validação local (antes do push)

| Verificação | Resultado |
|---|---|
| `npm run lint` (ESLint) | Passou |
| `npm run test:ci` (Jest) | 10 testes passaram, 90% de cobertura de statements |
| `terraform fmt -check -recursive` | Passou |
| `terraform validate` em `terraform/` e `bootstrap/` | Válido |
| YAML dos 3 workflows | Sintaxe válida |

Essas verificações não acessam a AWS.

## Execução real na AWS (Learner Lab, 25/10/2026)

| Etapa | Execução | Evidência |
|---|---|---|
| Apply inicial (11 recursos) | [run 40243554160](https://github.com/rafadical/unifaat-devops-portfolio/actions/runs/40243554160) | [evidencias/apply-initial.txt](evidencias/apply-initial.txt) |
| Pipeline CD (lint → test → build/push ECR → deploy → health check) | [run 40243739843](https://github.com/rafadical/unifaat-devops-portfolio/actions/runs/40243739843) | [evidencias/cd-pipeline.txt](evidencias/cd-pipeline.txt) |
| Plan comentado no PR | [PR #1](https://github.com/rafadical/unifaat-devops-portfolio/pull/1) | [evidencias/plan-pr-comment.md](evidencias/plan-pr-comment.md) |
| Apply após o merge (regra HTTPS 443) | [run 40244007318](https://github.com/rafadical/unifaat-devops-portfolio/actions/runs/40244007318) | [evidencias/apply-after-merge.txt](evidencias/apply-after-merge.txt) |

**Ajuste feito durante a revisão do PR #1:** a primeira versão usava `aws_security_group_rule` separado. Como o SG já tem regras inline, cada apply removeria a regra criada pelo outro recurso. A regra foi movida para um bloco `ingress` inline no mesmo PR, e o plan final ficou `0 to add, 1 to change, 0 to destroy`. É exatamente o tipo de problema que o plan no PR existe para pegar.

**Infraestrutura destruída em 25/10/2026** após a coleta das evidências (`terraform destroy` em `terraform/` e `bootstrap/`, bucket do state esvaziado e removido), para não consumir o crédito do Learner Lab. Os links acima continuam válidos; o endereço da API não responde mais.

## Autenticação

No Learner Lab o GitHub Actions usa as credenciais temporárias de sessão, porque o Lab não permite criar OIDC provider nem roles IAM. Em produção, o correto seria OIDC + `role-to-assume`, sem nenhuma chave guardada. Detalhes em [`gitops-cd-analise.md`](gitops-cd-analise.md#2-autenticação-na-aws).
