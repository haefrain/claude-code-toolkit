---
description: Pre-commit checklist — lint, typecheck, tests relacionados, diff stat y sugerencia de mensaje de commit.
argument-hint: "[path]"
---

1. Corre `~/.claude/scripts/commit-ready.sh $ARGUMENTS`
2. Analiza el diff staged completo: `git diff --cached`
3. Basado en los archivos y el diff, sugiere un mensaje de commit siguiendo la convención exacta del repo (analiza los últimos 5 commits).

El mensaje debe incluir:
- Tipo (`feat`, `fix`, `refactor`, `chore`, `test`, etc.)
- Scope entre paréntesis si el repo lo usa
- Descripción imperativa en el idioma del repo
- Co-Authored-By al final si aplica

No commitees. Solo prepara y sugiere.
