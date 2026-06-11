---
description: Inicializa y construye el índice CodeGraph en el proyecto actual para habilitar inteligencia de código en las sesiones.
argument-hint: ""
---

Ejecuta en secuencia:

```bash
codegraph init .
codegraph index .
codegraph status .
```

Presenta:
- Cuántos archivos y símbolos fueron indexados
- El estado final del índice (`codegraph status`)
- Confirmación: "CodeGraph inicializado. Las próximas sesiones tendrán inteligencia de código disponible automáticamente en el contexto inicial."

A partir de ahora, en este repo usá las tools MCP de codegraph (codegraph_context, codegraph_search, codegraph_trace, codegraph_impact) ANTES de explorar con grep/read manual.

Si `codegraph` no está instalado, muestra:
"CodeGraph no está instalado. Corré `npm install -g @colbymchenry/codegraph` o reinstalá el toolkit con `bash install.sh`."
