# Analise do Uso de IA - Aula 02 TF

## Prompt utilizado

Crie um ambiente Docker Compose para uma aplicacao Node.js 20 com Express, PostgreSQL 15 e Redis 7. A API deve usar a porta 3000. O PostgreSQL deve ter volume nomeado para persistencia. Os tres servicos devem compartilhar uma rede bridge customizada. Use variaveis interpoladas de um arquivo `.env`, healthchecks, `depends_on` com `condition: service_healthy` e `restart: unless-stopped`. Gere tambem uma API simples com as rotas `/` e `/health`.

## Rascunho inicial da IA

O rascunho inicial propunha os tres servicos principais, imagens versionadas, uma rede customizada, volume para o PostgreSQL e dependencias entre a API e os servicos de suporte. A estrutura era suficiente para iniciar o trabalho, mas ainda precisava de revisao antes de ser usada.

```yaml
services:
  api:
    build: .
    ports:
      - "${PORT}:3000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
  postgres:
    image: postgres:15-alpine
    volumes:
      - postgres-data:/var/lib/postgresql/data
  redis:
    image: redis:7-alpine

networks:
  technova-net:
    driver: bridge

volumes:
  postgres-data:
```

## Alteracoes manuais

| Alteracao | Motivo |
|---|---|
| Adicionei healthchecks completos aos tres servicos | A API precisa aguardar disponibilidade real, nao apenas a criacao do container. |
| Configurei `depends_on` com condicoes de saude | Evita iniciar a API antes de PostgreSQL e Redis estarem prontos. |
| Passei credenciais e hosts pelo `.env` | Evita valores sensiveis hardcoded no Compose. |
| Configurei o volume com nome explicito | Facilita verificar persistencia e administrar o volume. |
| Adicionei `restart: unless-stopped` | Permite recuperacao automatica em falhas locais. |
| Fixei as imagens em `postgres:15-alpine` e `redis:7-alpine` | Evita mudanças inesperadas causadas por `latest`. |
| Adicionei healthcheck HTTP para a API | Valida a aplicacao, alem de validar apenas os containers de infraestrutura. |

## O que a IA acertou

- Separou os servicos em API, banco e cache.
- Escolheu imagens leves e versionadas.
- Indicou o uso de rede e volume nomeado.
- Apontou `depends_on` e healthchecks como mecanismos de inicializacao ordenada.

## O que a IA errou ou omitiu

- O rascunho nao garantia que todas as variaveis chegariam a cada container.
- Um `depends_on` sem healthcheck nao prova que o servico esta pronto.
- Redis nao precisava de senha para este laboratorio, mas a comunicacao deveria permanecer restrita a rede Compose.
- A configuracao precisava de `.env.example` para documentar as variaveis sem publicar credenciais reais.
- A API precisava ser validada com `docker compose config` e testes reais, porque YAML aparentemente correto ainda pode falhar em runtime.

## Minha avaliacao

- **Tempo economizado usando IA:** aproximadamente 25 minutos.
- **Tempo gasto revisando e ajustando:** aproximadamente 35 minutos.
- **Nota para o rascunho:** 7/10.
- **Usaria novamente:** sim, para obter uma primeira estrutura e uma lista de verificacao; a validacao final de seguranca, sintaxe e funcionamento continua sendo responsabilidade do desenvolvedor.
