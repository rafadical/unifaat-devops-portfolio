## 🤖 AI Code Review — TechNova

| Severidade | Quantidade |
|---|:---:|
| 🔴 CRITICAL | 0 |
| 🟡 WARNING | 2 |
| 🔵 INFO | 1 |

✅ **Quality gate: aprovado** — só há WARNING/INFO; revise, mas o merge está liberado.

### Achados

| Severidade | Arquivo:linha | Problema | Código |
|---|---|---|---|
| 🟡 WARNING | `aula-09/demo-ai-review/relatorio-pedidos.js:15` | console.log em código de produção: prefira um logger com níveis. | `console.log('relatorio exportado');` |
| 🟡 WARNING | `aula-09/demo-ai-review/relatorio-pedidos.js:16` | catch vazio: o erro é silenciado e o bug fica escondido. | `} catch (e) {}` |
| 🔵 INFO | `aula-09/demo-ai-review/relatorio-pedidos.js:17` | Comentário TODO/FIXME: resolver ou abrir issue antes do merge. | `// TODO: mover o relatorio para um bucket S3` |

---
*Review automatizado (motor de regras, aula 09). Falsos positivos são possíveis: avalie cada achado. Não substitui o review humano.*

