#!/usr/bin/env bash
# rate-limit-audit.sh — endpoints sin rate limiting detectado (Next.js/Express/Laravel).
# Uso: rate-limit-audit.sh [path]
set -euo pipefail
path="${1:-.}"
cd "$path"

echo "## Rate Limit Audit — $path"
echo ""

exclude='--exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=.git --exclude-dir=vendor'

# Detectar rutas de API en Next.js
if [[ -d app ]]; then
  echo "### Next.js route handlers (app/)"
  routes=$(find app -name 'route.ts' -o -name 'route.js' 2>/dev/null)
  total=0; protected=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    total=$((total+1))
    if grep -qE '(ratelimit|rateLimiter|upstash|limiter|rate_limit)' "$f" 2>/dev/null; then
      echo "  ✅ $f"
      protected=$((protected+1))
    else
      echo "  ❌ $f"
    fi
  done <<< "$routes"
  echo ""
  echo "Protegidos: $protected/$total"
  echo ""
fi

# Express/Fastify
express_routes=$(grep -rln $exclude --include='*.ts' --include='*.js' \
  -E '(app|router)\.(get|post|put|patch|delete)\(' . 2>/dev/null)
if [[ -n "$express_routes" ]]; then
  echo "### Express/Fastify route files"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    has_rl=$(grep -lE '(rateLimit|rateLimiter|throttle|express-rate-limit)' "$f" 2>/dev/null || true)
    [[ -n "$has_rl" ]] && echo "  ✅ $f" || echo "  ❌ $f"
  done <<< "$express_routes"
  echo ""
fi

# Laravel (busca throttle middleware)
if [[ -d routes ]]; then
  echo "### Laravel routes"
  for f in routes/api.php routes/web.php; do
    [[ -f "$f" ]] || continue
    throttle=$(grep -cE "throttle:" "$f" 2>/dev/null || echo 0)
    total_routes=$(grep -cE "Route::" "$f" 2>/dev/null || echo 0)
    echo "  $f: throttle en $throttle/$total_routes rutas"
  done
  echo ""
fi

echo "### Patrones de rate limit encontrados (global)"
grep -rn $exclude --include='*.ts' --include='*.js' --include='*.php' \
  -E '(ratelimit|rateLimiter|upstash.*limit|express-rate-limit|throttle|@Throttle)' \
  . 2>/dev/null | grep -v 'node_modules' | head -15 || echo "(ninguno)"
