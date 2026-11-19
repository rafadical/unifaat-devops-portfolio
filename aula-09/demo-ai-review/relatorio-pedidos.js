// Arquivo de DEMONSTRAÇÃO do TF 09: CRITICAL corrigidos; restam só WARNING/INFO.
const { execFile } = require('child_process');
const db = require('./db');

const STATUS_PERMITIDOS = ['pending', 'shipped', 'delivered'];

function filtrarPedidos(req) {
  const status = STATUS_PERMITIDOS.includes(req.query.status) ? req.query.status : 'pending';
  return db.query('SELECT * FROM orders WHERE status = $1', [status]);
}

function exportarRelatorio(req) {
  execFile('zip', ['/tmp/relatorio.zip', String(req.query.arquivo)]);
  try {
    console.log('relatorio exportado');
  } catch (e) {}
  // TODO: mover o relatorio para um bucket S3
}

module.exports = { filtrarPedidos, exportarRelatorio };
