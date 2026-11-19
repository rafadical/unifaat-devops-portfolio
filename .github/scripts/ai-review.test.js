// Testes do motor de regras do AI review.  Rodar: node --test .github/scripts/
const test = require('node:test');
const assert = require('node:assert');
const { analyzeDiff, generateReport, summarize, RULES, MARKER } = require('./ai-review');

// Monta um diff unificado com as linhas informadas adicionadas ao arquivo
function diffOf(file, lines) {
  return [
    `diff --git a/${file} b/${file}`,
    `--- a/${file}`,
    `+++ b/${file}`,
    `@@ -1,0 +1,${lines.length} @@`,
    ...lines.map((l) => '+' + l)
  ].join('\n');
}

const rulesFound = (diff) => analyzeDiff(diff).map((f) => f.rule);

test('detecta mais de 8 padrões diferentes', () => {
  assert.ok(new Set(RULES.map((r) => r.id)).size > 8);
});

test('CRITICAL: secret hardcoded, eval, SQL injection, command injection', () => {
  const found = rulesFound(diffOf('src/app.js', [
    'const password = "admin123";',
    'const result = eval(req.body.expr);',
    'db.query("SELECT * FROM users WHERE id = " + req.params.id);',
    'exec(`ls ${req.query.dir}`);',
    'const fn = new Function(code);'
  ]));
  for (const id of ['hardcoded-secret', 'eval', 'sql-injection', 'command-injection', 'new-function']) {
    assert.ok(found.includes(id), `deveria detectar ${id}`);
  }
});

test('WARNING: console.log, catch vazio e debugger', () => {
  const found = rulesFound(diffOf('src/app.js', [
    'console.log("debug");',
    'try { x(); } catch (e) {}',
    '  debugger;'
  ]));
  assert.deepStrictEqual(found.sort(), ['console-log', 'debugger', 'empty-catch']);
});

test('Dockerfile: FROM sem versão e USER root', () => {
  const found = rulesFound(diffOf('app/Dockerfile', ['FROM node', 'USER root']));
  assert.deepStrictEqual(found.sort(), ['docker-latest', 'docker-user-root']);
  assert.deepStrictEqual(rulesFound(diffOf('app/Dockerfile', ['FROM node:20-alpine AS deps'])), []);
});

test('não analisa linhas removidas nem arquivos ignorados', () => {
  const removed = [
    '--- a/src/app.js',
    '+++ b/src/app.js',
    '@@ -1,1 +1,0 @@',
    '-const r = eval(x);'
  ].join('\n');
  assert.deepStrictEqual(analyzeDiff(removed), []);
  assert.deepStrictEqual(rulesFound(diffOf('__tests__/app.test.js', ['eval(x)'])), []);
  assert.deepStrictEqual(rulesFound(diffOf('README.md', ['password = "exemplo123"'])), []);
});

test('código limpo não gera achado', () => {
  assert.deepStrictEqual(rulesFound(diffOf('src/app.js', [
    'const db = require("./db");',
    'db.query("SELECT * FROM orders WHERE id = $1", [id]);',
    'const token = process.env.API_TOKEN;'
  ])), []);
});

test('informa a linha correta no arquivo novo', () => {
  const diff = [
    '--- a/src/app.js',
    '+++ b/src/app.js',
    '@@ -10,3 +10,4 @@',
    ' const a = 1;',
    ' const b = 2;',
    '+const r = eval(x);',
    ' module.exports = r;'
  ].join('\n');
  assert.strictEqual(analyzeDiff(diff)[0].line, 12);
});

test('relatório: gate bloqueado com CRITICAL e aprovado só com WARNING', () => {
  const crit = analyzeDiff(diffOf('a.js', ['eval(x)']));
  const warn = analyzeDiff(diffOf('a.js', ['console.log(x)']));
  assert.match(generateReport(crit), /BLOQUEADO/);
  assert.match(generateReport(warn), /Quality gate: aprovado/);
  assert.ok(generateReport([]).startsWith(MARKER));
  assert.deepStrictEqual(summarize(crit), { critical: 1, warning: 0, info: 0, total: 1 });
});
