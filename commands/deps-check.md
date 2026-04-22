---
description: Audit de dependencias clasificado por severidad y facilidad de fix.
argument-hint: "[path opcional]"
---

Corre `~/.claude/scripts/dep-triage.sh $ARGUMENTS` y presenta el resultado.

Luego, solo para las vulnerabilidades **critical + high**:
- Agrupa en dos buckets:
  - 🟢 **Patch-safe**: fix auto disponible, cambio de patch o minor version.
  - 🔴 **Breaking**: requiere major version bump o intervención manual.
- Para cada bucket, indica el comando exacto de upgrade.

NO corras el upgrade. Solo reporta. Si hay algo en 🔴, sugiere delegar al `dependency-auditor`.
