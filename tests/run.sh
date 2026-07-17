#!/usr/bin/env bash
# run.sh — corre todos los tests del toolkit (scripts bash planos, sin frameworks).
set -uo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$dir"/test-*.sh; do
  bash "$t" || rc=1
done
if [[ $rc -eq 0 ]]; then echo "✅ Todos los tests pasaron"; else echo "❌ Hay tests fallando"; fi
exit $rc
