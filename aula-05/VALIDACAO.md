# Resultado da validação local — TF 05

Aluno: rafael nogueira maruca — RA 6322006

## Resultado

Código validado localmente com Terraform 1.13.5 e provider hashicorp/aws 5.100.0. A instalação do provider verificou a assinatura HashiCorp e gerou os arquivos .terraform.lock.hcl.

| Verificação executada | Resultado |
|---|---|
| terraform init -backend=false nos dois projetos | Passou |
| terraform fmt -check -recursive | Passou |
| terraform validate — infraestrutura principal | Success! The configuration is valid. |
| terraform validate — backend | Success! The configuration is valid. |
| terraform test — infraestrutura principal | 3 passed, 0 failed |
| terraform test — backend | 1 passed, 0 failed |
| Seis arquivos exigidos pelo pré-check do professor | Todos presentes |
| git check-ignore para tfvars, state, backup, .terraform, pem e backend.hcl | Todos excluídos |

Os testes usam mock_provider e command=plan: não acessam AWS e não criam recursos reais. Verificam rede com duas AZs, parâmetros do RDS, ausência de rotas de internet nas subnets privadas, regra de acesso PostgreSQL, classe da EC2, IMDSv2, rejeição de SSH aberto para toda a internet, rejeição de senha curta, versionamento, bloqueio público, criptografia e chave LockID.

## Correções encontradas durante os testes

- O identificador do RDS começava com RA numérico; foi corrigido para technova-6322006-aula05-db, porque a AWS exige letra inicial.
- A tabela privada passou a declarar route=[] explicitamente, evitando deixar rotas extras sem gestão pelo código.
- O teste do SG foi ajustado para a representação null de listas opcionais no schema do provider.

## Backend aplicado na AWS (AWS Academy Learner Lab)

O backend remoto (`aula-05/backend`) foi aplicado com sucesso contra a conta real do AWS Academy Learner Lab (Account 533129404111):

- Bucket `6322006-technova-tfstate-533129404111-us-east-1` criado via AWS CLI (o SCP do Learner Lab nega `s3:GetBucketObjectLockConfiguration`, então o bucket é criado fora do Terraform e gerenciado apenas nas sub-configurações — ver `backend/bootstrap.ps1`).
- `terraform apply` em `aula-05/backend`: versionamento, criptografia SSE-AES256, bloqueio de acesso público e política de negação de tráfego não-TLS aplicados. `Apply complete! Resources: 4 added, 0 changed, 0 destroyed.`
- Tabela DynamoDB `6322006-technova-aula05-locks` confirmada (lock table).
- Log real em `evidencias/backend-apply.txt`.

## O que ainda não foi verificado

- `terraform apply` da infraestrutura principal (VPC, RDS, EC2) contra recursos reais.
- Instalação real do psql pelo user_data e conectividade SSH.
- SELECT version(), SELECT de orders e persistência após reiniciar a EC2.
- Plan real com No changes e destruição real da infraestrutura/backend.
- Pré-check remoto e avaliação do professor no GitHub: PR de entrega ainda não foi aberto.

Não existe nota atribuída pelo professor, nem garantia de aprovação baseada apenas nesses testes.

## Repetir os testes locais

Na pasta aula-05/, com Terraform no PATH:

```powershell
terraform init -backend=false -input=false
terraform validate
terraform fmt -check -recursive
terraform test
terraform -chdir=backend init -backend=false -input=false
terraform -chdir=backend validate
terraform -chdir=backend test
```

Para executar na AWS e coletar evidências, seguir README.md. Antes da publicação, completar o entrega.md com os resultados reais; não substituir por este relatório de testes simulados.
