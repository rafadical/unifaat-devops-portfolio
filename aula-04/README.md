# Infraestrutura TechNova — Aula 04

## Visão geral

Esta infraestrutura provisiona uma VPC com quatro subnets em duas Availability Zones, um Internet Gateway, security groups com regra mínima, uma EC2 pública e um perfil de instância para acesso S3 de leitura. O desenho busca garantir alta disponibilidade básica e uma separação clara entre redes públicas e privadas.

## Diagrama da arquitetura

```text
                      Internet
                          |
                          v
                 +--------------------+
                 |  Internet Gateway  |
                 +--------------------+
                          |
          ------------------------------------------------
          |                                              |
  [Public subnet AZ-A 10.0.1.0/24]             [Public subnet AZ-B 10.0.3.0/24]
          |                                              |
          |       EC2 API (t2.micro + User Data)        |
          |       SSH 22 / API 3000 open                |
          ------------------------------------------------
                          |
                  [VPC 10.0.0.0/16]
                          |
          ------------------------------------------------
          |                                              |
 [Private subnet AZ-A 10.0.2.0/24]         [Private subnet AZ-B 10.0.4.0/24]
          |                                              |
      (futuro banco / serviços internos)             (futuro banco / serviços internos)
```

## Como usar

### Pré-requisitos

- Terraform instalado
- AWS CLI configurado
- Chave SSH pública no formato OpenSSH em `var.public_key`
- Acesso ao AWS Academy Learner Lab ou conta AWS com permissões para VPC, EC2 e IAM

### Comandos

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

### Testar a API

```bash
curl http://<IP_PUBLICO>:3000
curl http://<IP_PUBLICO>:3000/health
```

### Conectar via SSH

```bash
ssh -i ~/.ssh/technova-key ec2-user@<IP_PUBLICO>
```

### Destruir

```bash
terraform destroy
```

## Decisões técnicas

- Multi-AZ: a arquitetura usa duas zonas de disponibilidade para reduzir o impacto de falhas em uma região.
- Público x privado: apenas recursos que exigem acesso externo ficam expostos; sub-redes privadas ficam reservadas para serviços internos e banco.
- Security Groups: regras mínimas com SSH e API expostos apenas no necessário, e SG do banco restrito à VPC.
- User Data: a EC2 instala Node.js, gera a API simples e a inicia automaticamente ao subir.

## Recursos criados

| Recurso | Função |
|---|---|
| VPC | rede principal da TechNova |
| Internet Gateway | conectividade de saída para internet |
| Subnets públicas | acesso externo e instância API |
| Subnets privadas | serviços internos e futuro banco |
| Security Group da API | expõe SSH e porta 3000 |
| Security Group do banco | acesso interno em 5432 |
| EC2 | executa a API |
| IAM Role + Instance Profile | acesso S3 somente leitura |
| Key Pair | autenticação SSH |
