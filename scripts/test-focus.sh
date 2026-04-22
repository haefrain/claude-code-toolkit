#!/usr/bin/env bash
# test-focus.sh — corre solo los tests relacionados al archivo editado.
# Uso: test-focus.sh [archivo] [path]
set -euo pipefail
file="${1:-}"
path="${2:-.}"
cd "$path"

detect_runner() {
  [[ -f jest.config.ts || -f jest.config.js ]] && echo "jest" && return
  [[ -f vitest.config.ts || -f vitest.config.js ]] && echo "vitest" && return
  [[ -f phpunit.xml || -f phpunit.xml.dist ]] && echo "phpunit" && return
  [[ -f pytest.ini || -f pyproject.toml ]] && grep -q '\[tool.pytest' pyproject.toml 2>/dev/null && echo "pytest" && return
  [[ -f pubspec.yaml ]] && echo "flutter_test" && return
  echo "unknown"
}

runner=$(detect_runner)
echo "## Test Focus — runner: $runner"
echo ""

if [[ -z "$file" ]]; then
  echo "Archivos modificados (candidatos a testear):"
  git diff --name-only HEAD 2>/dev/null | head -15
  echo ""
  echo "Especificá un archivo: test-focus.sh <archivo>"
  exit 0
fi

echo "Archivo: $file"
echo ""

case "$runner" in
  jest)
    mgr="npx"
    [[ -f pnpm-lock.yaml ]] && mgr="pnpm"
    [[ -f yarn.lock ]] && mgr="yarn"
    echo "### Corriendo tests relacionados"
    $mgr jest --passWithNoTests --findRelatedTests "$file" 2>&1 | tail -30
    ;;
  vitest)
    npx vitest related "$file" --run 2>&1 | tail -30
    ;;
  phpunit)
    # intenta encontrar el test correspondiente al archivo PHP
    test_file=$(echo "$file" | sed 's|src/|tests/|; s|\.php$|Test.php|')
    [[ -f "$test_file" ]] && php artisan test "$test_file" || php artisan test --filter "$(basename "$file" .php)"
    ;;
  pytest)
    python -m pytest -x -q --tb=short -k "$(basename "$file" .py | sed 's/\./_/g')" 2>&1 | tail -30
    ;;
  flutter_test)
    flutter test "$file" 2>&1 | tail -30
    ;;
  *)
    echo "(runner desconocido — especificá el comando manualmente)"
    ;;
esac
