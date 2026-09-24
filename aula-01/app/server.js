const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (request, response) => {
  response.json({
    servico: 'DevOps Portfolio API',
    aluno: 'Rafael Nogueira Maruca',
    ra: '6322006',
    aula: '01 - Fundamentos de Git e Docker',
    status: 'online',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (request, response) => {
  response.json({
    status: 'healthy',
    uptime: process.uptime(),
    version: '1.0.0'
  });
});

app.get('/info', (request, response) => {
  response.json({
    empresa: 'TechNova',
    projeto: 'Portfolio DevOps - UniFAAT 2026-2',
    equipe: 'Platform Engineering',
    ambiente: process.env.NODE_ENV || 'development'
  });
});

app.listen(port, () => {
  console.log(`Portfolio API rodando na porta ${port}`);
});
