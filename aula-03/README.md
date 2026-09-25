# Aula 03 — Terraform + IAM | Rafael Nogueira Maruca (RA 6322006)

## Design da Estrutura IAM

A estrutura foi organizada em grupos por responsabilidade, seguindo o princípio de separar acesso por papel funcional. O grupo `SEURA-technova-developers` concentra as permissões mínimas para leitura de buckets da TechNova e a política `SEURA-technova-deny-destructive` atua como guardrail para impedir ações perigosas como `Delete*` e `Terminate*`. O grupo `SEURA-technova-platform-eng` recebe permissão para gestão de instâncias EC2 e acesso ao armazenamento S3 de dados da aplicação.

Os usuários foram distribuídos para refletir a realidade da equipe: `SEURA-juliana-dev` é desenvolvedora com leitura restrita, `SEURA-rafael-platform` fica em ambos os grupos e `SEURA-lucas-intern` permanece apenas no grupo de desenvolvimento com políticas mais limitadas.

## Princípio do Menor Privilégio

O princípio do menor privilégio exige que cada identidade receba apenas o acesso necessário para executar suas funções. Neste projeto, a política de leitura S3 inclui apenas `s3:GetObject` e `s3:ListBucket`, sem permissões de escrita ou exclusão. A policy de plataforma adiciona controle de EC2 e acesso ao bucket de dados, mas sem liberar ações destrutivas. Se fosse usada a política `AmazonS3FullAccess`, por exemplo, um desenvolvedor poderia apagar ou sobrescrever objetos críticos, aumentando o risco de perda de dados e reduzindo a rastreabilidade de ações.

## Diagrama de Permissões

```text
User / Group / Policy / Resource

SEURA-juliana-dev
  └── SEURA-technova-developers
        ├── SEURA-technova-s3-read
        │      └── technova-* buckets
        └── SEURA-technova-deny-destructive
               └── bloqueia Delete*, Terminate*, etc.

SEURA-rafael-platform
  ├── SEURA-technova-developers
  └── SEURA-technova-platform-eng
        └── SEURA-technova-ec2-s3-full
              ├── EC2 Describe/Start/Stop em recursos da TechNova
              └── S3 read/write em technova-app-data-*

SEURA-technova-ec2-role
  └── EC2 -> S3 app-data
        └── instancia profile SEURA-technova-ec2-profile
```

## Comandos Utilizados

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

> Observação: a execução real de `terraform plan`/`apply` depende de credenciais válidas da AWS (como as do AWS Academy Learner Lab). No ambiente local atual, a tentativa de execução falhou por ausência de credenciais, mas a estrutura do código está pronta para ser aplicada no ambiente correto.

## Reflexão

Criar IAM manualmente no Console AWS exige cliques repetidos, pouca rastreabilidade e alta chance de configurções inconsistentes. Com Terraform, a mesma base fica declarada em código, versionável no Git, revisável em pull request e reproduzível em qualquer ambiente. Para uma equipe, essa abordagem é muito mais segura, auditável e escalável, porque toda alteração passa por revisão antes de ser aplicada.
