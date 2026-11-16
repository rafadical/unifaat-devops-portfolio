# Aula 08 — GitHub Actions e CI Pipelines

[![CI Pipeline — Aula 08](https://github.com/rafadical/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml/badge.svg)](https://github.com/rafadical/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml)

**Aluno:** rafael nogueira maruca — **RA:** 6322006

Pipeline de integração contínua para a TechNova API: a cada push na `main` ou Pull Request que altera `aula-08/technova-api/`, o GitHub Actions roda lint, testes e build da imagem Docker.

## Pipeline

Workflow: [`.github/workflows/ci-aula08.yml`](../.github/workflows/ci-aula08.yml) (na raiz do repositório, onde o GitHub executa os workflows).

```
lint ──► test (Node 18) ──┐
     └─► test (Node 20) ──┴─► build (docker build + smoke test) ──► pr-comment (só em PR)
```

| Job | O que faz | Depende de |
|---|---|---|
| **Lint (ESLint)** | `npm ci` + `npm run lint` | — |
| **Testes (Jest)** | `npm test` com coverage, em matrix Node 18 e 20; publica o relatório de coverage como artifact | lint |
| **Build Docker + Smoke Test** | usa o secret `AWS_REGION`; `docker build` com tag `${{ github.sha }}`; sobe o container, chama `/health` e remove | test |
| **Comentar resultado no PR** | comenta a tabela de resultados no Pull Request | lint, test, build |

### Requisitos atendidos

| Requisito | Onde |
|---|---|
| R1 — Multi-stage com `needs` | `lint → test → build` |
| R2 — ESLint | [`technova-api/.eslintrc.json`](technova-api/.eslintrc.json) com `semi`, `quotes`, `no-unused-vars`, `indent`, `eol-last` |
| R3 — Jest | [`technova-api/__tests__/server.test.js`](technova-api/__tests__/server.test.js): 10 testes em 5 endpoints (`GET /health`, `GET /version`, `GET /api/orders`, `GET /api/orders/:id`, `POST /api/orders`), cobertura de 90% das linhas |
| R4 — Docker build | [`technova-api/Dockerfile`](technova-api/Dockerfile) multi-stage, usuário não-root, `HEALTHCHECK` |
| R5 — Secret | `AWS_REGION` em Settings → Secrets, referenciado como `${{ secrets.AWS_REGION }}` (valor fictício, aparece como `***` no log) |
| R6 — Badge | no topo deste README e no README da raiz |
| B1 — Matrix | Node 18 e 20 |
| B2 — Cache | `actions/setup-node` com `cache: npm` |
| B3 — PR comment | job `pr-comment` |
| B4 — Concurrency | `concurrency` com `cancel-in-progress: true` |
| B5 — Smoke test | job `build` sobe o container e testa `/health` |

## Rodar localmente

```bash
cd aula-08/technova-api
npm ci
npm run lint
npm test
docker build -t technova-api:local .
docker run --rm -p 3000:3000 technova-api:local
curl http://localhost:3000/health
```

## Evidências

Ver [`evidencias/`](evidencias/) e [`screenshots/`](screenshots/), e as respostas conceituais em [`RESPOSTAS.md`](RESPOSTAS.md).
