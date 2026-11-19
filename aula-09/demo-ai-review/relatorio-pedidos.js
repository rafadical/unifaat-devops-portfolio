// Arquivo de DEMONSTRAÇÃO do TF 09: contém problemas de propósito para o AI review.
const { exec } = require('child_process');
const db = require('./db');

const password = 'admin123';

function filtrarPedidos(req) {
  const filtro = eval(req.query.filtro);
  return db.query('SELECT * FROM orders WHERE status = ' + req.query.status, filtro);
}

function exportarRelatorio(req) {
  exec(`zip /tmp/relatorio.zip ${req.query.arquivo}`);
  try {
    console.log('relatorio exportado', password);
  } catch (e) {}
  // TODO: mover o relatorio para um bucket S3
}

module.exports = { filtrarPedidos, exportarRelatorio };
