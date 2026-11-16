# RESPOSTAS — Aula 08: GitHub Actions e CI Pipelines

**Aluno:** rafael nogueira maruca — **RA:** 6322006

## Questões de múltipla escolha (TA da aula 08)

### Questão 1 — O que dispara a execução de um workflow?

**Resposta: b)** Eventos configurados no campo `on:` do YAML, como `push`, `pull_request` ou `workflow_dispatch`.

O workflow é orientado a eventos. No `ci-aula08.yml` usei três: `push` na `main`, `pull_request` para a `main` (ambos filtrados por `paths`, só quando `aula-08/technova-api/` ou o próprio workflow mudam) e `workflow_dispatch` para rodar manualmente. As outras alternativas estão erradas: não existe execução periódica automática sem um `schedule` (cron) declarado; clicar em "Run" só funciona quando há `workflow_dispatch`; e não há dependência de um administrador fazer deploy.

### Questão 2 — Função do `needs` em um workflow multi-stage

**Resposta: c)** Cria dependência entre jobs: o job só executa se os jobs listados em `needs` passarem.

Sem `needs`, os jobs rodam em paralelo. No pipeline, `test` tem `needs: lint` e `build` tem `needs: test`, então uma imagem Docker só é construída a partir de código que passou no lint e nos testes. Se o lint falha, `test` e `build` aparecem como *skipped*. O job `pr-comment` usa `needs: [lint, test, build]` junto com `if: always()` para rodar mesmo quando algum falha e conseguir reportar a falha no PR.

### Questão 3 — Onde armazenar credenciais AWS

**Resposta: c)** Em GitHub Secrets (Settings → Secrets and variables → Actions), referenciadas com `${{ secrets.NAME }}`.

Secrets ficam criptografados, não aparecem no código e o GitHub substitui o valor por `***` nos logs. No TF usei o secret `AWS_REGION` (valor fictício) e o log do job de build mostra `Regiao configurada via secret: ***`. Commitar `.env` (a) expõe a credencial no histórico do Git para sempre, mesmo que o arquivo seja apagado depois; `runs-on` (b) só escolhe o runner; e não existe campo `credentials:` (d). Em produção o ideal é nem guardar chave: usar OIDC com uma role IAM e credenciais de curta duração.

### Questão 4 — Propósito de environments com approval gates

**Resposta: b)** Garantir que deploys para ambientes sensíveis (como produção) exijam aprovação humana antes de executar.

Um *environment* (ex.: `production`) pode ter *required reviewers*: o job que o referencia fica pausado até alguém aprovar. Ele também permite secrets por ambiente e registra o histórico de deploys. É a diferença prática entre Continuous Delivery (com aprovação) e Continuous Deployment (sem aprovação).

## Conceitos aplicados no pipeline

**O que o CI resolve na TechNova.** Antes, o código ia para o servidor sem lint e sem testes, e erro só era descoberto em produção. Com CI, todo push e todo PR são verificados em minutos, por uma máquina limpa, do mesmo jeito sempre. Um PR com erro fica vermelho e não deveria ser mergeado.

**Por que `npm ci` e não `npm install`.** `npm ci` instala exatamente as versões do `package-lock.json` e falha se ele estiver inconsistente com o `package.json`. O build fica reprodutível: o que passou no CI é o que foi testado.

**Cache (B2).** `actions/setup-node` com `cache: npm` guarda o cache do npm entre execuções, usando o hash do `package-lock.json` como chave. Se as dependências não mudam, a instalação é mais rápida.

**Matrix (B1).** O mesmo job de teste roda em Node 18 e 20 em paralelo. `fail-fast: false` deixa as duas versões terminarem, para saber exatamente em qual delas algo quebrou.

**Concurrency (B4).** Se eu der dois pushes seguidos na mesma branch, a execução antiga é cancelada: não faz sentido gastar minutos testando um commit que já foi substituído.

**Smoke test (B5).** `docker build` passar não garante que a aplicação sobe. O job de build inicia o container, chama `/health` e só passa se receber resposta. O container é removido com `if: always()`, mesmo se o teste falhar.

**Pipeline falhando de propósito (R7).** Abri um PR com um erro de lint intencional (ponto e vírgula faltando). O job de lint falhou, os jobs seguintes foram pulados por causa do `needs`, e o comentário automático no PR mostrou o ❌. O PR foi fechado sem merge.
