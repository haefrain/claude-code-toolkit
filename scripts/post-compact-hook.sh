#!/usr/bin/env bash
# post-compact-hook.sh — SessionStart(matcher: compact): reinyecta reglas críticas
# después de que Claude Code compacta el contexto (las instrucciones se diluyen al resumir).
# Input stdin JSON (no usado). Este hook jamás rompe la sesión.
set -uo pipefail

cat <<'EOF'
<!-- post-compact: reglas críticas reinyectadas -->

Recordatorios vigentes tras la compactación de contexto:

- **Idioma:** SIEMPRE responder en español.
- **Verificación (S01):** evidencia antes de afirmaciones; el hook Stop corre `.claude/verify.sh` — no evadirlo. `FULL=1` SOLO a solicitud explícita de Efraín. `/simplify` antes de entregar cambios no triviales.
- **SDD (S05):** tracks→misiones con `buk-track`/`buk-mision`; nunca inventar datos de negocio (`[PENDIENTE: …]`); repos ajenos → exclude local, jamás comitear artefactos SDD.
- **Issues:** toda tarea persistente → GitHub Issues (`for:efrain` / `for:claude`).
- **Subagentes:** prohibición git enumerada en cada despacho; merge/push solo con OK de Efraín.
EOF

# Modo voz: recordarlo solo si está activo
if [[ -f "$HOME/.claude/voz-on" ]]; then
  echo "- **Modo voz ACTIVO** (voz: $(cat "$HOME/.claude/voz-on" 2>/dev/null || echo Paulina)): hablar el resumen al final de cada respuesta sustantiva."
fi

exit 0
