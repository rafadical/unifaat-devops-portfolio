const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (request, response) => {
  response.json({
    servico: 'TechNova API - Aula 02 TF',
    aluno: 'Rafael Nogueira Maruca',
    ra: '6322006',
    status: 'online',
    banco: `${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`,
    cache: `${process.env.REDIS_HOST}:${process.env.REDIS_PORT}`,
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (request, response) => {
  response.json({
    status: 'healthy',
    servicos: {
      api: 'online',
      banco: `${process.env.DB_HOST}:${process.env.DB_PORT}`,
      cache: `${process.env.REDIS_HOST}:${process.env.REDIS_PORT}`
    },
    uptime: process.uptime()
  });
});

app.listen(port, () => {
  console.log(`TechNova API rodando na porta ${port}`);
  console.log(`Banco: ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`);
  console.log(`Cache: ${process.env.REDIS_HOST}:${process.env.REDIS_PORT}`);
});
