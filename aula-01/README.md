# Aula 01 - Fundamentos de Git e Docker

## O que aprendi

- Git registra o historico completo do projeto e permite recuperar alteracoes sem depender de arquivos ZIP.
- Branches isolam uma funcionalidade antes do merge na `main`.
- Commits pequenos e mensagens Conventional Commits tornam o historico rastreavel.
- Docker empacota a aplicacao e suas dependencias em um ambiente reproduzivel.
- O `.gitignore` e o `.dockerignore` evitam versionar ou copiar arquivos desnecessarios e segredos.

## Comandos Git praticados

- `git init`, `git status`, `git add` e `git commit`
- `git branch`, `git checkout`, `git merge` e `git log --oneline --graph`
- `git remote`, `git push`, `git pull` e `git clone`

## Comandos Docker praticados

- `docker build`, `docker run`, `docker ps` e `docker logs`
- `docker stop`, `docker start`, `docker rm` e `docker exec`
- `docker stats` e uso de variaveis com `-e`

## Como executar localmente

```bash
cd aula-01/app
npm install
npm start
```

A API fica disponível em `http://localhost:3000`.

## Como executar com Docker

```bash
cd aula-01/app
docker build -t portfolio-aula01:1.0 .
docker run --rm --name portfolio-aula01 -p 3000:3000 portfolio-aula01:1.0
```

Endpoints validados:

- `GET /`
- `GET /health`
- `GET /info`

## Dificuldades encontradas

A principal dificuldade foi separar os arquivos da aplicacao dos arquivos de infraestrutura da Aula 05. A organizacao em `aula-01/app` manteve cada aula independente e permitiu que o Docker recebesse apenas o contexto da aplicacao. Tambem foi necessario configurar os arquivos de exclusao para evitar que `node_modules`, logs e `.env` fossem enviados ao repositorio ou para dentro da imagem.
