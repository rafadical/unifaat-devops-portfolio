# Aula 02 - Docker Compose e IA como Copiloto

## Objetivo

A Aula 02 transforma a API da Aula 01 em um ambiente local multi-container com API, PostgreSQL e Redis. O Compose centraliza rede, persistencia, healthchecks e variaveis de ambiente em um arquivo versionado.

## Servicos

- `api`: Express com Node.js 20, exposta na porta 3000.
- `postgres`: PostgreSQL 15 Alpine com o volume nomeado `technova-postgres-data`.
- `redis`: Redis 7 Alpine com AOF habilitado.

Todos os servicos usam a rede customizada `technova-net`. A API so inicia depois que PostgreSQL e Redis passam nos healthchecks.

## Executar

1. Copie `.env.example` para `.env` e altere a senha local.
2. Suba o ambiente:

```bash
docker compose up -d --build
```

3. Valide a configuracao e o estado:

```bash
docker compose config
docker compose ps
curl http://localhost:3000
curl http://localhost:3000/health
docker compose exec postgres pg_isready -U technova -d technova
docker compose exec redis redis-cli ping
```

A resposta esperada do Redis e `PONG`. Para parar sem apagar o volume:

```bash
docker compose down
```

Para remover tambem os dados persistidos do PostgreSQL:

```bash
docker compose down -v
```

## IA como copiloto

O arquivo [ia-analise.md](ia-analise.md) registra o prompt, o rascunho inicial, as alteracoes manuais e os limites encontrados. A IA acelerou a estrutura inicial, mas a configuracao final foi revisada contra os requisitos do TF e deve ser validada com Docker Compose.

## Dificuldades encontradas

A principal decisao foi separar configuracao de desenvolvimento (`.env`) do template versionado (`.env.example`) e garantir que o Compose interpolasse hosts de servico, em vez de usar `localhost` entre containers. A validacao de runtime depende do Docker Desktop ativo.
