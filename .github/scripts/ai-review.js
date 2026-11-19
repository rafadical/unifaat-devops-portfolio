#!/usr/bin/env node
// ============================================
// AI Review da TechNova (aula 09)
// ============================================
// Analisa só as linhas ADICIONADAS no diff do PR e classifica os achados
// em CRITICAL, WARNING e INFO. O Bedrock não está disponível no Learner Lab,
// então a "IA" aqui é um motor de regras; analyzeDiff() é o ponto onde uma
// chamada a um LLM entraria (ver aula-09/ia-cicd-analise.md).
//
// Uso:  DIFF_FILE=pr.diff node .github/scripts/ai-review.js [--gate]
//       --gate: termina com exit 1 se houver achado CRITICAL.

const fs = require('fs');

const SEVERITY = {
  CRITICAL: 'CRITICAL',
  WARNING: 'WARNING',
  INFO: 'INFO'
};

const ICON = {
  CRITICAL: '🔴 CRITICAL',
  WARNING: '🟡 WARNING',
  INFO: '🔵 INFO'
};

const MARKER = '<!-- technova-ai-review -->';

const isCode = (file) => /\.(c|m)?(js|ts)x?$/.test(file);
const isDockerfile = (file) => /(^|\/)Dockerfile[^/]*$/.test(file);
const isShell = (file) => /\.sh$/.test(file) || isDockerfile(file);
const any = () => true;

// Arquivos que não são revisados: o próprio revisor (contém os padrões como
// texto), testes (usam dados falsos de propósito), docs e lockfiles.
const IGNORED = [
  /^\.github\/scripts\//,
  /(^|\/)(__tests__|tests?)\//,
  /\.(test|spec)\.(c|m)?(js|ts)x?$/,
  /\.md$/,
  /(^|\/)package-lock\.json$/
];

const RULES = [
  // ---- CRITICAL: bloqueiam o PR ----
  {
    id: 'hardcoded-secret',
    severity: SEVERITY.CRITICAL,
    appliesTo: any,
    regex: /\b(password|passwd|pwd|secret|api[_-]?key|token|access[_-]?key)\w*\b['"]?\s*[:=]\s*['"`][^'"`\s]{4,}['"`]/i,
    message: 'Possível secret/credencial hardcoded. Use GitHub Secrets ou variáveis de ambiente.'
  },
  {
    id: 'aws-access-key',
    severity: SEVERITY.CRITICAL,
    appliesTo: any,
    regex: /\b(AKIA|ASIA)[0-9A-Z]{16}\b/,
    message: 'Access key da AWS no código. Revogue a chave e use credenciais temporárias.'
  },
  {
    id: 'private-key',
    severity: SEVERITY.CRITICAL,
    appliesTo: any,
    regex: /-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----/,
    message: 'Chave privada versionada.'
  },
  {
    id: 'eval',
    severity: SEVERITY.CRITICAL,
    appliesTo: isCode,
    regex: /\beval\s*\(/,
    message: 'Uso de eval(): risco de code injection.'
  },
  {
    id: 'new-function',
    severity: SEVERITY.CRITICAL,
    appliesTo: isCode,
    regex: /\bnew\s+Function\s*\(/,
    message: 'new Function() executa string como código (equivalente a eval).'
  },
  {
    id: 'command-injection',
    severity: SEVERITY.CRITICAL,
    appliesTo: isCode,
    regex: /\b(exec|execSync|spawn|spawnSync)\s*\(\s*(`[^`]*\$\{|['"][^'"]*['"]\s*\+)/,
    message: 'Comando de shell montado com dados dinâmicos: risco de command injection.'
  },
  {
    id: 'sql-injection',
    severity: SEVERITY.CRITICAL,
    appliesTo: isCode,
    regex: /\b(query|execute|raw)\s*\(\s*(`[^`]*\b(select|insert|update|delete)\b[^`]*\$\{|['"][^'"]*\b(select|insert|update|delete)\b[^'"]*['"]\s*\+)/i,
    message: 'SQL montado por concatenação/template: risco de SQL injection. Use queries parametrizadas.'
  },
  {
    id: 'tls-disabled',
    severity: SEVERITY.CRITICAL,
    appliesTo: any,
    regex: /rejectUnauthorized\s*:\s*false|NODE_TLS_REJECT_UNAUTHORIZED\s*=\s*['"]?0/,
    message: 'Validação de certificado TLS desativada (permite man-in-the-middle).'
  },

  // ---- WARNING: aparecem no comentário, não bloqueiam ----
  {
    id: 'console-log',
    severity: SEVERITY.WARNING,
    appliesTo: isCode,
    regex: /\bconsole\.(log|debug|info)\s*\(/,
    message: 'console.log em código de produção: prefira um logger com níveis.'
  },
  {
    id: 'empty-catch',
    severity: SEVERITY.WARNING,
    appliesTo: isCode,
    regex: /\bcatch\s*(\(\s*\w*\s*\))?\s*\{\s*\}/,
    message: 'catch vazio: o erro é silenciado e o bug fica escondido.'
  },
  {
    id: 'debugger',
    severity: SEVERITY.WARNING,
    appliesTo: isCode,
    regex: /^\s*debugger\s*;?\s*$/,
    message: 'Instrução debugger esquecida.'
  },
  {
    id: 'docker-user-root',
    severity: SEVERITY.WARNING,
    appliesTo: isDockerfile,
    regex: /^\s*USER\s+(root|0)\s*$/i,
    message: 'Container rodando como root.'
  },
  {
    id: 'docker-latest',
    severity: SEVERITY.WARNING,
    appliesTo: isDockerfile,
    regex: /^\s*FROM\s+(?!scratch\b)[^\s:@]+(:latest)?(\s+AS\s+\S+)?\s*$/i,
    message: 'Imagem base sem versão fixa (ou :latest): build não reprodutível.'
  },
  {
    id: 'chmod-777',
    severity: SEVERITY.WARNING,
    appliesTo: isShell,
    regex: /\bchmod\s+(-R\s+)?0?777\b/,
    message: 'Permissão 777: qualquer usuário pode alterar o arquivo.'
  },

  // ---- INFO ----
  {
    id: 'todo',
    severity: SEVERITY.INFO,
    appliesTo: any,
    regex: /\b(TODO|FIXME|HACK|XXX)\b/,
    message: 'Comentário TODO/FIXME: resolver ou abrir issue antes do merge.'
  },
  {
    id: 'insecure-http',
    severity: SEVERITY.INFO,
    appliesTo: any,
    regex: /['"`]http:\/\/(?!localhost|127\.0\.0\.1|0\.0\.0\.0)[^'"`]+['"`]/,
    message: 'URL http:// sem TLS.'
  }
];

function isIgnored(file) {
  return IGNORED.some((re) => re.test(file));
}

// Percorre o diff unificado guardando arquivo e número da linha no arquivo novo
function analyzeDiff(diff) {
  const findings = [];
  let file = null;
  let newLine = 0;

  for (const line of diff.split(/\r?\n/)) {
    if (line.startsWith('+++ ')) {
      file = line === '+++ /dev/null' ? null : line.replace(/^\+\+\+ b\//, '');
      continue;
    }
    const hunk = line.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/);
    if (hunk) {
      newLine = Number(hunk[1]);
      continue;
    }
    if (!file || line.startsWith('---') || line.startsWith('diff ') || line.startsWith('index ')) {
      continue;
    }
    if (line.startsWith('+')) {
      const code = line.slice(1);
      if (!isIgnored(file)) {
        for (const rule of RULES) {
          if (rule.appliesTo(file) && rule.regex.test(code)) {
            findings.push({
              rule: rule.id,
              severity: rule.severity,
              file,
              line: newLine,
              code: code.trim(),
              message: rule.message
            });
          }
        }
      }
      newLine++;
    } else if (!line.startsWith('-') && !line.startsWith('\\')) {
      newLine++; // linha de contexto
    }
  }
  return findings;
}

function summarize(findings) {
  const count = (s) => findings.filter((f) => f.severity === s).length;
  return {
    critical: count(SEVERITY.CRITICAL),
    warning: count(SEVERITY.WARNING),
    info: count(SEVERITY.INFO),
    total: findings.length
  };
}

const escapeCell = (text, max = 60) => {
  const short = text.length > max ? text.slice(0, max - 3) + '...' : text;
  return short.replace(/\|/g, '\\|').replace(/`/g, '\'');
};

function generateReport(findings) {
  const s = summarize(findings);
  const header = `${MARKER}\n## 🤖 AI Code Review — TechNova\n\n`;
  const footer = '\n---\n*Review automatizado (motor de regras, aula 09). ' +
    'Falsos positivos são possíveis: avalie cada achado. Não substitui o review humano.*\n';

  if (s.total === 0) {
    return header + '✅ **Nenhum problema encontrado** nas linhas adicionadas por este PR.\n\n' +
      '**Quality gate:** ✅ aprovado\n' + footer;
  }

  const gate = s.critical > 0
    ? `⛔ **Quality gate: BLOQUEADO** — ${s.critical} achado(s) CRITICAL precisam ser corrigidos antes do merge.`
    : '✅ **Quality gate: aprovado** — só há WARNING/INFO; revise, mas o merge está liberado.';

  const order = [SEVERITY.CRITICAL, SEVERITY.WARNING, SEVERITY.INFO];
  const sorted = [...findings].sort((a, b) => order.indexOf(a.severity) - order.indexOf(b.severity));

  let body = header;
  body += '| Severidade | Quantidade |\n|---|:---:|\n';
  body += `| ${ICON.CRITICAL} | ${s.critical} |\n| ${ICON.WARNING} | ${s.warning} |\n| ${ICON.INFO} | ${s.info} |\n\n`;
  body += `${gate}\n\n### Achados\n\n`;
  body += '| Severidade | Arquivo:linha | Problema | Código |\n|---|---|---|---|\n';
  for (const f of sorted) {
    body += `| ${ICON[f.severity]} | \`${escapeCell(f.file, 45)}:${f.line}\` | ${f.message} | \`${escapeCell(f.code, 50)}\` |\n`;
  }
  return body + footer;
}

function main() {
  const diffFile = process.env.DIFF_FILE || 'pr.diff';
  const outFile = process.env.REVIEW_OUTPUT || 'ai-review-result.md';
  const diff = fs.readFileSync(diffFile, 'utf8');

  const findings = analyzeDiff(diff);
  const s = summarize(findings);
  fs.writeFileSync(outFile, generateReport(findings));

  console.log(`Achados: ${s.total} (CRITICAL ${s.critical}, WARNING ${s.warning}, INFO ${s.info})`);
  for (const f of findings) {
    console.log(`  [${f.severity}] ${f.file}:${f.line} ${f.rule}`);
  }

  if (process.env.GITHUB_OUTPUT) {
    fs.appendFileSync(process.env.GITHUB_OUTPUT,
      `critical=${s.critical}\nwarning=${s.warning}\ninfo=${s.info}\ntotal=${s.total}\n`);
  }

  if (process.argv.includes('--gate') && s.critical > 0) {
    console.error(`Quality gate: ${s.critical} achado(s) CRITICAL. PR bloqueado.`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { analyzeDiff, generateReport, summarize, RULES, SEVERITY, MARKER };
