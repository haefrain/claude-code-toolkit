#!/usr/bin/env bash
# Contrato de verificación del claude-code-toolkit.
# Rápido por defecto; no hay suite lenta, FULL no agrega nada extra.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# Sintaxis de todos los scripts bash
for f in scripts/*.sh install.sh tests/*.sh config/templates/verify/*.sh .claude/verify.sh; do
  bash -n "$f"
done

# Tests del toolkit
bash tests/run.sh
