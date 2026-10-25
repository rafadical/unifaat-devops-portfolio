# Análise — GitOps de Terraform e Pipeline CD (Aula 10)

**Aluno:** rafael nogueira maruca — **RA:** 6322006

## 1. Fluxo GitOps implementado

```
branch feat/*  ──►  PR para main  ──►  terraform-plan.yml  ──►  comentário com o plan
                                                                    │ revisão humana
merge na main  ──►  terraform-apply.yml  ──►  terraform apply -auto-approve
```

- **Fonte da verdade:** o estado desejado da infraestrutura é o que está em `aula-10/terraform/` na `main`. Ninguém roda `terraform apply` na própria máquina.
- **Por que plan no PR:** o revisor vê exatamente o que vai ser criado, alterado ou destruído antes de aprovar. Um `-/+ destroy and then create replacement` inesperado em uma EC2 aparece no comentário, não em produção. O workflow também roda `fmt -check` e `validate`, e falha se o plan falhar, então um PR quebrado fica vermelho.
- **Por que apply no merge:** o merge é o registro auditável da aprovação (quem aprovou, quando, qual commit). O `-auto-approve` é seguro porque o plan já foi revisado e o CI não tem terminal interativo.
- **Proteções adicionais:**
  - `concurrency: terraform-aula10` impede dois plans/applies simultâneos (além do lock no DynamoDB).
  - State remoto em S3 com versionamento e criptografia, criado pelo `bootstrap/`.
  - Branch protection na `main` exigindo PR e o check "Terraform Plan" verde.
- **Limite conhecido:** o plan comentado é gerado no momento do PR. Se outra mudança entrar na `main` antes do merge, o apply pode diferir do plan revisado. Mitigação: exigir branch atualizada antes do merge (opção "Require branches to be up to date").

## 2. Autenticação na AWS

| | Learner Lab (implementado) | Produção (ideal) |
|---|---|---|
| Mecanismo | 3 credenciais temporárias da sessão como GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) | OIDC: o GitHub emite um token assinado e a AWS troca por credenciais de uma role IAM (`role-to-assume`) |
| Segredos guardados | Sim, e expiram a cada sessão do Lab | Nenhum |
| Escopo | O que a `LabRole` permitir | Role com menor privilégio e trust policy restrita ao repositório/branch |
| Manutenção | Atualizar os 3 secrets toda vez que o Lab reinicia | Nenhuma rotação manual |

**Por que OIDC é o ideal:** não existe chave de longa duração para vazar, cada execução recebe credenciais que duram minutos, e a trust policy pode limitar a `repo:rafadical/unifaat-devops-portfolio:ref:refs/heads/main`.

**Por que o Lab não permite:** OIDC exige criar um *IAM OIDC Identity Provider* e uma *role IAM* com trust policy, e o AWS Academy Learner Lab bloqueia a criação de recursos IAM. A configuração equivalente em produção seria:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform
    aws-region: us-east-1
# + permissions: id-token: write
```

O ponto positivo das credenciais do Lab é que elas são temporárias: se vazarem, expiram junto com a sessão.

## 3. Estratégia Recreate

Implementação (`cd.yml`, job `deploy`): login no ECR → `docker pull` da tag `sha-<commit>` → `docker stop` → `docker rm` → `docker run` → health check.

| Prós | Contras |
|---|---|
| Simples de implementar e entender | Downtime entre o `stop` e o novo container responder |
| Só uma versão roda por vez (sem conflito de schema ou sessão) | Se a nova versão não sobe, a aplicação fica fora até o rollback |
| Usa os recursos de uma única EC2 (barato) | Não permite testar a versão nova com tráfego real antes da troca |

**Quando usar:** ambientes de desenvolvimento/homologação, sistemas internos que toleram segundos de indisponibilidade, aplicações que não podem rodar duas versões ao mesmo tempo, e uma startup com uma instância como a TechNova hoje. Para zero downtime, o próximo passo é Blue/Green ou Canary com ALB (aula 11).

**Detalhe implementado:** o deploy usa a tag imutável `sha-<commit>` em vez de `latest`. Assim o que roda é exatamente o que foi testado, e o rollback é só apontar para outra tag. O health check também consulta `/version` e falha se o commit em execução não for o do pipeline, evitando um "falso verde" com o container antigo.

## 4. Continuous Delivery vs Continuous Deployment

| | Continuous Delivery | Continuous Deployment |
|---|---|---|
| Até onde o pipeline vai sozinho | Até um artefato pronto para produção | Até produção |
| Gatilho do deploy | Aprovação humana (botão / reviewer) | Merge na main |
| Risco | Menor, alguém decide o momento | Exige testes e monitoramento confiáveis |
| Neste projeto | Basta adicionar *Required reviewers* no environment `production` | **Implementado**: push na main → deploy automático |

O job `deploy` já usa `environment: production`, então trocar de Deployment para Delivery é uma configuração no GitHub, sem mudar o YAML.

## 5. Rollback

Procedimento completo em [docs/runbook-rollback.md](docs/runbook-rollback.md). Resumo: identificar a última tag `sha-*` estável no ECR, fazer SSH na EC2, **fazer login no ECR antes do pull**, e recriar o container com a tag antiga. O lifecycle policy do ECR mantém as 10 imagens mais recentes, que é a janela de rollback.

O rollback também pode ser feito via Git: `git revert` do commit problemático e push na main. O próprio pipeline reconstrói e implanta a versão anterior, deixando registro no histórico.

## 6. Limitações identificadas e melhorias

| Limitação | Melhoria |
|---|---|
| Credenciais do Lab expiram e precisam ser recadastradas nos secrets | OIDC + role IAM fora do Lab |
| Porta 22 aberta para `0.0.0.0/0` (IPs dos runners variam) | Restringir aos ranges de `api.github.com/meta`, usar AWS SSM Run Command (sem SSH) ou um runner self-hosted na VPC |
| Downtime durante o Recreate | Blue/Green com ALB e dois target groups |
| Rollback manual | Rollback automático quando o health check falha (`docker run` da tag anterior no próprio job) |
| As credenciais de sessão são enviadas à EC2 para o login no ECR | Instance profile com permissão de leitura no ECR (no Lab, `LabInstanceProfile`) |
| Uma única EC2 em uma AZ | Auto Scaling Group ou ECS em duas AZs |
| Health check só verifica `/health` | Smoke tests das rotas principais e alertas no CloudWatch |
