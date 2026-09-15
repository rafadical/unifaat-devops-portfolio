# TF Aula 05 — RDS e Remote State

**Aluno:** rafael nogueira maruca — **RA:** 6322006

A solução provisiona a rede da TechNova, uma EC2 com cliente PostgreSQL e um RDS privado. Um projeto Terraform separado cria o bucket do state e a tabela de locking. A implementação local não representa prova de execução na AWS; consulte VALIDACAO.md para os testes realmente realizados.

## Arquitetura e decisões

VPC 10.0.0.0/16; subnet pública 10.0.1.0/24 com EC2 t2.micro; subnets privadas 10.0.2.0/24 e 10.0.3.0/24 em AZs distintas para o DB Subnet Group. Apenas a tabela pública possui rota 0.0.0.0/0 para o Internet Gateway. O RDS PostgreSQL 15 usa db.t3.micro, 20 GB gp2 criptografados, sem IP público e sem Multi-AZ. Seu SG só permite 5432 a partir do SG da EC2. SSH fica restrito ao IP /32 do aluno.

O TF exige a conexão por psql e uma regra para a porta 3000; este projeto instala o cliente PostgreSQL na EC2. Não inclui uma API Node.js, que não é requisito explícito do exercício do TF 05. A persistência é demonstrada pela tabela orders no RDS.

O backend usa S3 com versionamento, AES256, bloqueio de acesso público e exigência de HTTPS, mais DynamoDB com LockID. DynamoDB foi mantido para cumprir o enunciado, embora versões recentes do Terraform indiquem sua depreciação para locking do backend S3. A senha é sensível e não vai em outputs nem user_data; ainda pode existir no state, que precisa continuar protegido.

O banco tem skip_final_snapshot=true e retenção de backup zero para permitir a limpeza do laboratório. São decisões deste exercício, não uma política de recuperação para produção. Não há NAT Gateway ou IAM adicional obrigatório, reduzindo requisitos de permissões no Learner Lab.

## Arquivos

| Arquivo | Responsabilidade |
|---|---|
| providers.tf | Versões, provider AWS, tags e backend parcial |
| main.tf | VPC, três subnets, IGW e tabelas/associações de rotas |
| ec2.tf / user-data.sh | AMI Amazon Linux 2023, chave pública, SG, EC2 e psql |
| rds.tf | DB Subnet Group, SG privado e PostgreSQL |
| variables.tf / outputs.tf | Configuração e dados de conexão sem senha |
| backend/main.tf | S3, controles de segurança e DynamoDB |
| sql/orders.sql | Cinco pedidos de teste; execução repetida não duplica IDs |
| terraform.tfvars.example / backend.hcl.example | Modelos sem credenciais |

## Pré-requisitos

Terraform 1.13.5 foi escolhido para a validação local; o código usa provider AWS 5.x. Usar AWS CLI, OpenSSH e sessão ativa no AWS Academy Learner Lab com permissões para EC2/VPC, RDS, S3 e DynamoDB. As credenciais temporárias incluem AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY e AWS_SESSION_TOKEN, configuradas somente no ambiente local. Não publicar credenciais, chaves privadas, arquivos de state nem planos binários.

Os comandos abaixo são PowerShell, executados em aula-05/. Se Terraform não estiver no PATH, adicionar temporariamente a pasta do executável portátil ao PATH da sessão. Confirmar a região autorizada pelo laboratório antes de criar recursos; us-east-1 é o padrão deste projeto.

## 1. Preparar parâmetros

```powershell
aws sts get-caller-identity
ssh-keygen -t ed25519 -f "$env:USERPROFILE/.ssh/technova-6322006"
Copy-Item terraform.tfvars.example terraform.tfvars
```

Não sobrescrever uma chave existente. Editar terraform.tfvars com o IP público real /32 e o caminho da chave .pub. O IP 203.0.113.10 é apenas exemplo documental e precisa ser substituído. Ler a senha sem exibi-la no terminal:

```powershell
$dbSecret = Read-Host 'Senha do RDS' -AsSecureString
$env:TF_VAR_db_password = [System.Net.NetworkCredential]::new('', $dbSecret).Password
```

## 2. Criar o backend primeiro

```powershell
terraform -chdir=backend init
terraform -chdir=backend validate
terraform -chdir=backend plan
terraform -chdir=backend apply
$stateBucket = terraform -chdir=backend output -raw bucket_name
$lockTable = terraform -chdir=backend output -raw dynamodb_table
@"
bucket = "$stateBucket"
region = "us-east-1"
dynamodb_table = "$lockTable"
"@ | Set-Content -Encoding ascii backend.hcl
```

Se usar outra região, passá-la ao backend (por exemplo com TF_VAR_aws_region) e ajustar backend.hcl e terraform.tfvars para a mesma região. O state do projeto bootstrap permanece local em backend/; preservá-lo de forma segura até a limpeza. Não colocar o próprio bootstrap no bucket que ele destruirá.

## 3. Criar infraestrutura principal

```powershell
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -lock-timeout=5m
terraform apply -lock-timeout=5m
```

O primeiro state principal já nasce no S3. Se estiver adaptando uma infraestrutura existente com state local, fazer backup seguro e usar terraform init -migrate-state -backend-config=backend.hcl para migrar; não usar essa opção como substituto de importar recursos sem state.

## 4. Coletar evidências reais

```powershell
New-Item -ItemType Directory -Force evidencias | Out-Null
aws s3 ls "s3://$stateBucket/aula-05/6322006/" | Tee-Object evidencias/state-s3.txt
terraform plan -no-color -detailed-exitcode -lock-timeout=5m > evidencias/terraform-plan-output.txt
$planExit = $LASTEXITCODE
if ($planExit -ne 0) { throw "Plan não está limpo. Código: $planExit (1=erro; 2=alterações)." }
$ec2Ip = terraform output -raw ec2_public_ip
terraform output -raw connection_string
scp -i "$env:USERPROFILE/.ssh/technova-6322006" sql/orders.sql "ec2-user@${ec2Ip}:/home/ec2-user/orders.sql"
ssh -i "$env:USERPROFILE/.ssh/technova-6322006" "ec2-user@$ec2Ip"
```

Dentro da EC2, esperar o user_data terminar e executar (substituindo ENDPOINT pelo rds_address, sem o sufixo :5432):

```bash
sudo cloud-init status --wait
psql --version
psql "host=ENDPOINT port=5432 dbname=technova user=technova_admin sslmode=require" -W -v ON_ERROR_STOP=1 -c "SELECT version();"
psql "host=ENDPOINT port=5432 dbname=technova user=technova_admin sslmode=require" -W -v ON_ERROR_STOP=1 -f /home/ec2-user/orders.sql
psql "host=ENDPOINT port=5432 dbname=technova user=technova_admin sslmode=require" -W -v ON_ERROR_STOP=1 -c "SELECT * FROM orders ORDER BY id;"
```

A senha é solicitada pelo psql. Capturar os resultados dos comandos e salvar em evidencias/conexao-rds.txt e evidencias/orders.txt, ou usar screenshots. Para demonstrar persistência após reiniciar a EC2, reiniciar somente a instância criada neste projeto, reconectar e executar novamente o SELECT sem reaplicar o INSERT. Salvar também essa consulta. Se alterar usuário ou nome do banco, ajustar os comandos.

Um SELECT bem-sucedido comprova conexão e dados; um plan limpo comprova que o código e o estado observado estão alinhados. Nenhuma dessas verificações isoladamente substitui as demais.

## 5. Limpar antes de abrir o PR

```powershell
terraform destroy -lock-timeout=5m
terraform state list
```

A lista do state principal deve ficar vazia. Salvar o resultado da destruição em evidencias/destroy.txt. Conferir no console a remoção do RDS e o término da EC2 do projeto. Em seguida, no console S3, abrir exclusivamente o bucket cujo nome veio de backend output bucket_name e usar Esvaziar, incluindo todas as versões e marcadores de exclusão. Não limpar buckets de colegas ou da conta por seleção ampla.

```powershell
terraform -chdir=backend destroy
Remove-Item Env:TF_VAR_db_password
```

Conferir a remoção do bucket e da tabela de locks do projeto; preservar os outputs de confirmação. force_destroy está desativado para exigir a limpeza explícita do bucket. Sem o esvaziamento de versões e delete markers, o destroy do backend falhará com BucketNotEmpty.

## 6. Entrega

Publicar esta pasta como aula-05/ no repositório público unifaat-devops-portfolio. Conferir as exclusões Git antes de adicionar arquivos. Manter .terraform.lock.hcl para reproduzir a versão do provider.

Preencher preparacao-entrega/entregas/aula-05/6322006/entrega.md, fora deste portfólio, com a URL verdadeira e as evidências. Esse é o único arquivo do TF a copiar para a branch entregas/aula-05/6322006 do fork da disciplina. Título do PR: [Aula 05] RA: 6322006 - rafael nogueira maruca.

As respostas de TA e trabalho em aula estão em respostas-aula-05/, no workspace, e não foram misturadas ao PR exclusivo do TF. Nenhuma data de aula, URL do aluno ou execução AWS deve ser inventada.
