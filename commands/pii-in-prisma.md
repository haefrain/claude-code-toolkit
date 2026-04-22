---
description: Detecta campos PII en schema.prisma sin cifrado declarado — email, phone, document, name, address, etc.
argument-hint: "[path]"
---

Corre `~/.claude/scripts/pii-in-prisma.sh $ARGUMENTS`. Los campos ⚠️ SIN CIFRAR son candidatos a issues `[GDPR-CRIT-NNN]` o `[GDPR-HIGH-NNN]`. Antes de crear el issue, verificar si el cifrado está en la capa de aplicación (no en Prisma) — buscar con `grep -rn "encrypt" lib/ app/ --include='*.ts'`.
