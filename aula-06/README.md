# Aula 06 — Biblioteca de Módulos Terraform da TechNova

**Aluno:** rafael nogueira maruca — **RA:** 6322006

## Visão geral

Biblioteca de módulos reutilizáveis (VPC, Security Group, EC2 e RDS) que provisiona um ambiente completo da TechNova na AWS com uma única composição de módulos. Os ambientes **dev** e **staging** usam exatamente o mesmo `main.tf` e os mesmos módulos; o que muda é só o `terraform.tfvars` de cada um (CIDRs, nomes, database).

## Arquitetura

```
                         environments/<ambiente>/main.tf
                                     │
                 ┌───────────────────┼────────────────────┐
                 ▼                   │                    │
          ┌─────────────┐            │                    │
          │ module.vpc  │            │                    │
          └──┬───┬───┬──┘            │                    │
     vpc_id  │   │   │ private_subnet_ids                 │
             │   │   └────────────────────────────┐       │
             ▼   │ public_subnet_ids[0]           │       │
   ┌──────────────────┐                           │       │
   │ module.api_sg    │── sg_id ──┐               │       │
   └──────────────────┘           │               │       │
             │ sg_id (origem)     ▼               │       │
             ▼            ┌───────────────┐       │       │
   ┌──────────────────┐   │ module.       │       │       │
   │ module.rds_sg    │   │ api_server    │◄──────┘ subnet│
   └────────┬─────────┘   │ (ec2)         │               │
            │ sg_id       └───────────────┘               │
            ▼                                             ▼
   ┌──────────────────────────────────────────────────────────┐
   │ module.database (rds) ◄── private_subnet_ids + rds_sg    │
   └──────────────────────────────────────────────────────────┘
```

Fluxo de composição (output de um módulo → input de outro):

| De | Output | Para | Input |
|---|---|---|---|
| vpc | `vpc_id` | api_sg, rds_sg | `vpc_id` |
| vpc | `public_subnet_ids[0]` | api_server (ec2) | `subnet_id` |
| vpc | `private_subnet_ids` | database (rds) | `subnet_ids` |
| api_sg | `sg_id` | api_server (ec2) | `security_group_ids` |
| api_sg | `sg_id` | rds_sg | `ingress_rules[].source_security_group_ids` |
| rds_sg | `sg_id` | database (rds) | `security_group_ids` |

O PostgreSQL só aceita conexões vindas do Security Group da API, nunca de um CIDR aberto.

## Estrutura

```
aula-06/
├── README.md
├── .gitignore
├── environments/
│   ├── dev/        main.tf · variables.tf · outputs.tf · providers.tf · terraform.tfvars · tests/
│   └── staging/    main.tf · variables.tf · outputs.tf · providers.tf · terraform.tfvars
├── modules/
│   ├── vpc/             main.tf · variables.tf · outputs.tf
│   ├── security-group/  main.tf · variables.tf · outputs.tf
│   ├── ec2/             main.tf · variables.tf · outputs.tf
│   └── rds/             main.tf · variables.tf · outputs.tf
└── evidencias/     saídas reais de fmt, validate e test
```

## Ambientes

| Aspecto | Dev | Staging |
|---|---|---|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Subnets públicas | 10.0.1.0/24, 10.0.2.0/24 | 10.1.1.0/24, 10.1.2.0/24 |
| Subnets privadas | 10.0.3.0/24, 10.0.4.0/24 | 10.1.3.0/24, 10.1.4.0/24 |
| EC2 | t2.micro | t2.micro |
| RDS | db.t3.micro (PostgreSQL 15) | db.t3.micro (PostgreSQL 15) |
| Database | technova_dev | technova_staging |
| Nomes | technova-dev-* | technova-staging-* |

Todos os recursos recebem as tags `Name`, `Project`, `Environment` e `ManagedBy` (via `default_tags` do provider + `Name` nos módulos).

---

## Módulos disponíveis

### Módulo VPC (`modules/vpc`)

**Descrição:** cria a VPC, as subnets dinamicamente com `for_each` a partir de um mapa, o Internet Gateway e as route tables (pública com rota para a internet; privada sem rota externa).

**Inputs:**

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `vpc_cidr` | string | Sim | CIDR da VPC (validado) |
| `project_name` | string | Sim | Prefixo dos nomes |
| `environment` | string | Sim | Ambiente |
| `subnets` | map(object({cidr, az, type})) | Sim | Subnets; `type` = `public` ou `private` (validado) |
| `tags` | map(string) | Não | Tags extras |

**Outputs:**

| Nome | Descrição |
|---|---|
| `vpc_id` | ID da VPC |
| `vpc_cidr` | CIDR da VPC |
| `public_subnet_ids` | IDs das subnets públicas (ordenados pelo nome lógico) |
| `private_subnet_ids` | IDs das subnets privadas (ordenados pelo nome lógico) |

**Exemplo:**

```hcl
module "vpc" {
  source       = "../../modules/vpc"
  vpc_cidr     = "10.0.0.0/16"
  project_name = "technova"
  environment  = "dev"
  subnets = {
    "public-1"  = { cidr = "10.0.1.0/24", az = "us-east-1a", type = "public" }
    "private-1" = { cidr = "10.0.3.0/24", az = "us-east-1a", type = "private" }
    "private-2" = { cidr = "10.0.4.0/24", az = "us-east-1b", type = "private" }
  }
}
```

### Módulo Security Group (`modules/security-group`)

**Descrição:** Security Group genérico (API, RDS, bastion…). As regras de entrada são uma lista de objetos transformada em blocos `ingress` com `dynamic`; a origem pode ser CIDR, outro Security Group ou ambos. Egress padrão: todo tráfego de saída.

**Inputs:**

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `name` | string | Sim | Sufixo do nome (ex.: `api`) |
| `vpc_id` | string | Sim | VPC do SG |
| `ingress_rules` | list(object) | Não (default `[]`) | `description`, `from_port`, `to_port`, `protocol` (default `tcp`), `cidr_blocks`, `source_security_group_ids` |
| `environment` | string | Sim | Ambiente |
| `project_name` | string | Sim | Prefixo |
| `description` | string | Não | Descrição do SG |
| `tags` | map(string) | Não | Tags extras |

Validação: toda regra precisa de pelo menos uma origem (CIDR ou SG).

**Outputs:**

| Nome | Descrição |
|---|---|
| `sg_id` | ID do Security Group |
| `sg_name` | Nome completo |

**Exemplo:**

```hcl
module "rds_sg" {
  source       = "../../modules/security-group"
  name         = "rds"
  vpc_id       = module.vpc.vpc_id
  project_name = "technova"
  environment  = "dev"
  ingress_rules = [{
    description               = "PostgreSQL vindo da API"
    from_port                 = 5432
    to_port                   = 5432
    source_security_group_ids = [module.api_sg.sg_id]
  }]
}
```

### Módulo EC2 (`modules/ec2`)

**Descrição:** instância EC2 com AMI, tipo, subnet, Security Groups e `user_data` opcional. Usa IMDSv2 obrigatório e disco criptografado.

**Inputs:**

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `instance_name` | string | Sim | Tag `Name` |
| `instance_type` | string | Não (`t2.micro`) | Tipo da instância |
| `ami_id` | string | Sim | AMI |
| `subnet_id` | string | Sim | Subnet |
| `security_group_ids` | list(string) | Sim | SGs |
| `key_name` | string | Não (`null`) | Key pair (no Learner Lab: `vockey`) |
| `user_data` | string | Não (`null`) | Script de inicialização |
| `associate_public_ip` | bool | Não (`true`) | IP público |
| `root_volume_size` | number | Não (`8`) | Disco em GB |

**Outputs:** `instance_id`, `public_ip`, `private_ip`.

**Exemplo:**

```hcl
module "api_server" {
  source             = "../../modules/ec2"
  instance_name      = "technova-dev-api"
  ami_id             = data.aws_ami.al2023.id
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.api_sg.sg_id]
  key_name           = "vockey"
}
```

### Módulo RDS (`modules/rds`)

**Descrição:** DB Subnet Group com as subnets privadas + instância PostgreSQL privada, criptografada e com configurações de desenvolvimento (`skip_final_snapshot`, sem deletion protection, sem backup) para destruir rápido no Learner Lab.

**Inputs:**

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `db_name` | string | Sim | Database inicial |
| `db_username` | string | Sim | Usuário master |
| `db_password` | string (sensitive) | Sim | Senha master (8–128, sem `/`, `@`, aspas, espaço) |
| `subnet_ids` | list(string) | Sim | Subnets privadas (mínimo 2, validado) |
| `security_group_ids` | list(string) | Sim | SGs do RDS |
| `instance_class` | string | Não (`db.t3.micro`) | Classe |
| `engine_version` | string | Não (`15`) | Versão do PostgreSQL |
| `allocated_storage` | number | Não (`20`) | GB |
| `environment` | string | Sim | Ambiente |
| `project_name` | string | Sim | Prefixo |

**Outputs:** `db_endpoint`, `db_address`, `db_name`, `db_port`.

**Exemplo:**

```hcl
module "database" {
  source             = "../../modules/rds"
  db_name            = "technova_dev"
  db_username        = "technova_admin"
  db_password        = var.db_password
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.rds_sg.sg_id]
  project_name       = "technova"
  environment        = "dev"
}
```

---

## Como usar

### Pré-requisitos

- Terraform ≥ 1.6 (testes com `mock_provider` exigem ≥ 1.7)
- AWS CLI v2 com as credenciais da sessão do **AWS Academy Learner Lab** (`aws sts get-caller-identity` funcionando), região `us-east-1`
- Key pair `vockey` (já existe no Learner Lab) ou outro informado em `key_name`

### Executar um ambiente

```bash
cd aula-06/environments/dev        # ou staging
export TF_VAR_db_password='UmaSenhaForte123'   # nunca versionar
terraform init
terraform validate
terraform plan
terraform apply                    # opcional
terraform destroy                  # sempre ao terminar
```

### Criar um novo ambiente (ex.: prod)

```bash
cp -r environments/staging environments/prod
# editar environments/prod/terraform.tfvars:
#   environment = "prod", vpc_cidr = "10.2.0.0/16", subnets 10.2.x.0/24, db_name = "technova_prod"
```

Nenhum módulo precisa ser alterado.

### Testes automatizados

```bash
cd aula-06/environments/dev
terraform test
```

O teste usa `mock_provider` (não cria nada na AWS) e verifica a composição nos dois cenários (dev e staging): 2 subnets públicas e 2 privadas, nome do database por ambiente e Security Groups separados para API e RDS.

## Validação executada

| Verificação | Resultado |
|---|---|
| `terraform fmt -check -recursive` | Sem diferenças |
| `terraform validate` (dev e staging) | Success |
| `terraform test` (dev e staging, provider simulado) | 2 passed, 0 failed |

Saída completa em [`evidencias/validate-test.txt`](evidencias/validate-test.txt). O `terraform plan` contra a AWS não foi executado nesta entrega (sessão do Learner Lab indisponível); o teste com `mock_provider` cobre a composição dos módulos sem acessar a AWS.

## Segurança e boas práticas

- `db_password` marcada como `sensitive` e passada só por `TF_VAR_db_password`; os `terraform.tfvars` versionados não contêm segredos.
- RDS sem acesso público, em subnets privadas sem rota para a internet, acessível apenas pelo SG da API.
- `.gitignore` exclui `.terraform/`, `*.tfstate` e planos; os `terraform.tfvars` dos ambientes são reincluídos de propósito.
- Variáveis com `type` e `description`; outputs com `description`; validações de CIDR, tipo de subnet, origem de regra, senha e quantidade de subnets do RDS.
