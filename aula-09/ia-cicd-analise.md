# Análise — Docker Registry e IA no CI/CD (Aula 09)

**Aluno:** rafael nogueira maruca — **RA:** 6322006

## 1. Por que o Amazon ECR como registry

| | Amazon ECR | ghcr.io | Docker Hub |
|---|---|---|---|
| Onde fica | Mesma conta/região AWS da infraestrutura | GitHub | Docker Inc. |
| Pull pela EC2/ECS | Rede interna da AWS, autenticação por credenciais AWS (ou instance profile) | Precisa de token do GitHub na máquina | Precisa de conta e tem limite de pulls anônimos |
| Segurança | Scan de vulnerabilidade no push, criptografia, política de acesso por IAM | Scan via Dependabot/Advanced Security | Scan pago |
| Retenção | Lifecycle policy nativa | Manual / Actions | Manual |

A TechNova já roda na AWS (aulas 03–06): a EC2 que vai fazer `docker pull` está na mesma região do ECR, a autenticação usa a mesma credencial AWS da infraestrutura e não é preciso guardar um segundo token (GitHub/Docker Hub) no servidor. É também o registry que as próximas aulas (deploy Recreate, Blue/Green) consomem.

**Restrições do AWS Academy Learner Lab e como lidei com elas:**

- **Não dá para criar usuário, grupo ou role IAM.** Não existe um "usuário de CI" com permissão mínima; o CI usa as 3 credenciais temporárias da sessão (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) como GitHub Secrets. Em produção isso seria OIDC + role com permissão só de push no repositório `technova-api`.
- **As credenciais expiram a cada sessão.** O `ecr-push.sh` é o fluxo principal (roda local com a sessão ativa); o workflow `ci-aula09.yml` faz o mesmo no GitHub Actions, mas depende de atualizar os secrets quando o Lab reinicia (erro típico: `ExpiredToken`).
- **Só `us-east-1`.** Região fixa no script e no workflow.
- **Recursos do Lab são apagados/encerrados com o tempo.** O script é idempotente: recria o repositório e reaplica a lifecycle policy se não existirem.

## 2. Estratégia de tagging

Toda imagem recebe **várias tags apontando para o mesmo digest**:

| Tag | Quando | Para quê |
|---|---|---|
| `sha-a1b2c3d` | Todo build | **Rastreabilidade**: a tag diz exatamente de qual commit a imagem saiu. É a tag usada em deploy e rollback, porque nunca é reaproveitada. |
| `latest` | Todo build da `main` | Conveniência para testes locais. **Nunca** para deploy: ela muda de imagem a cada build, então "rodar latest" hoje e amanhã pode ser coisa diferente. |
| `1.2.3` | Git tag `v1.2.3` | Release comunicável para a equipe (semver). |
| `1.2` e `1` | Git tag `v1.2.3` | Permitem acompanhar a última correção (`1.2`) ou a última versão compatível (`1`) da release. |

O semver vem da **git tag**, não de um arquivo editado à mão: `git tag v1.0.1 && git push origin v1.0.1` dispara o pipeline, e o `ecr-push.sh` lê a tag com `git describe --exact-match`. Assim a versão da imagem e a versão do código ficam sempre amarradas ao mesmo commit.

**Rollback por tag:** como cada versão continua no ECR, voltar é só baixar a tag anterior (`./ecr-rollback.sh 1.0.0`, ou o workflow `ci-aula09.yml` com `rollback_tag=1.0.0`). A lifecycle policy mantém as 20 imagens mais recentes e remove as sem tag após 1 dia, limitando custo sem apagar o histórico recente de rollback.

## 3. O que o AI review verifica

Script: [`.github/scripts/ai-review.js`](../.github/scripts/ai-review.js), com 8 testes automatizados em [`ai-review.test.js`](../.github/scripts/ai-review.test.js). Analisa **só as linhas adicionadas** pelo PR e informa arquivo e linha do arquivo novo.

| # | Padrão | Severidade | Arquivos |
|---|---|---|---|
| 1 | Secret hardcoded (`password`, `token`, `api_key`… = "literal") | CRITICAL | todos |
| 2 | Access key da AWS (`AKIA…`/`ASIA…`) | CRITICAL | todos |
| 3 | Chave privada (`-----BEGIN … PRIVATE KEY-----`) | CRITICAL | todos |
| 4 | `eval()` | CRITICAL | JS/TS |
| 5 | `new Function()` | CRITICAL | JS/TS |
| 6 | Command injection (`exec`/`spawn` com template ou concatenação) | CRITICAL | JS/TS |
| 7 | SQL injection (SQL montado com `+` ou `${}`) | CRITICAL | JS/TS |
| 8 | TLS desativado (`rejectUnauthorized: false`, `NODE_TLS_REJECT_UNAUTHORIZED=0`) | CRITICAL | todos |
| 9 | `console.log/debug/info` | WARNING | JS/TS |
| 10 | `catch` vazio | WARNING | JS/TS |
| 11 | `debugger` esquecido | WARNING | JS/TS |
| 12 | `USER root` | WARNING | Dockerfile |
| 13 | `FROM` sem versão ou `:latest` | WARNING | Dockerfile |
| 14 | `chmod 777` | WARNING | shell/Dockerfile |
| 15 | `TODO`/`FIXME`/`HACK` | INFO | todos |
| 16 | URL `http://` sem TLS (exceto localhost) | INFO | todos |

Arquivos ignorados de propósito: o próprio revisor (contém os padrões como texto), testes (usam dados falsos), `.md` e `package-lock.json`.

## 4. Lógica da análise e do quality gate

```
PR aberto/atualizado
  → checkout com histórico (fetch-depth: 0)
  → node --test (o revisor é testado antes de revisar)
  → git diff origin/main...HEAD > pr.diff
  → ai-review.js: para cada linha "+", aplica as regras do tipo de arquivo
  → comenta no PR (ou ATUALIZA o comentário anterior, identificado por um marcador HTML)
  → quality gate:
        CRITICAL > 0  → exit 1 → check "AI Code Review" vermelho → merge bloqueado
        só WARNING/INFO → exit 0 → check verde → merge liberado (com os avisos no comentário)
```

**Por que essa divisão de severidade:** CRITICAL é o que causa incidente de segurança se chegar à `main` e quase nunca tem uso legítimo em código de aplicação (credencial no código, execução de string, SQL concatenado, TLS desligado). WARNING é qualidade/higiene: vale avisar, mas bloquear um `console.log` atrasaria o time sem ganho real. INFO é lembrete.

**Onde entraria um LLM:** o Bedrock não está disponível no Learner Lab, então a análise é um motor de regras. Com um LLM, o mesmo workflow mandaria o diff com um prompt do tipo:

> "Você é revisor de segurança de uma API Node.js. Analise apenas as linhas adicionadas deste diff. Para cada problema, responda em JSON com `severity` (CRITICAL só para vulnerabilidade explorável ou credencial exposta; WARNING para qualidade; INFO para sugestão), `file`, `line`, `message` e `suggestion`. Não invente problemas fora do diff."

As regras atuais continuariam rodando antes, como rede de segurança determinística: um LLM pode deixar passar um secret que uma regex nunca deixa.

## 5. Quando confiar na IA e quando exigir review humano

**Confio na automação para:** padrões objetivos e repetitivos (secret no código, `eval`, `console.log`, Dockerfile sem versão). São coisas que um humano cansado deixa passar e a máquina pega 100% das vezes, sempre igual.

**Exijo review humano para:**
- Regra de negócio e lógica (o revisor não sabe se um pedido pode ter quantidade zero).
- Autenticação, autorização e dados pessoais (LGPD).
- Mudanças de arquitetura, de infraestrutura (Terraform) e de dependências.
- **Todo achado CRITICAL que alguém queira contestar**: o gate bloqueia, um humano confirma se é falso positivo e decide.
- PR verde no AI review **não** significa código seguro; significa só que nenhum dos 16 padrões apareceu.

## 6. Limitações identificadas

| Limitação | Exemplo | Mitigação |
|---|---|---|
| **Falso positivo** | `const password = "<placeholder>"` num exemplo; `http://` num comentário | Ignorar testes e `.md`; humano decide; em evolução, permitir supressão explícita por linha (`// ai-review-ignore`) |
| **Falso negativo** | Secret dividido em duas linhas, SQL montado em variável antes do `query()`, secret em base64 | Somar ferramentas especializadas (gitleaks, Semgrep/CodeQL) e o scan do ECR |
| **Contexto limitado** | Analisa linha a linha do diff, não entende o fluxo do dado de `req.body` até o banco | LLM com o arquivo inteiro como contexto, ou análise estática com taint tracking |
| **Só linhas adicionadas** | Um problema antigo no arquivo não aparece | Scan completo periódico do repositório (workflow de segurança) |
| **Regras fixas** | Só pega o que alguém previu | Revisar e ampliar as regras a partir de incidentes reais; testes garantem que regra nova não quebra as antigas |
| **Dependências** | Não vê vulnerabilidade em pacote npm | Workflow separado `security-scan.yml` (`npm audit` + Trivy) e `scanOnPush` no ECR |
