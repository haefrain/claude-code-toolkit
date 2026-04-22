#!/usr/bin/env bash
# auth-routes-audit.sh — lista endpoints con/sin protección de auth.
# Uso: auth-routes-audit.sh [path]
set -euo pipefail
path="${1:-.}"
cd "$path"

echo "## Auth Routes Audit — $path"
echo ""

exclude='--exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=.git'

# ---- Next.js app router ----
if [[ -d app ]]; then
  echo "### Next.js App Router — route.ts handlers"
  total=0; protected=0; unprotected_list=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    total=$((total+1))
    # patrones de auth: auth(), getSession, getServerSession, requireAuth, verifyToken, currentUser
    if grep -qE '(auth\(\)|getSession|getServerSession|requireAuth|verifyToken|currentUser|withAuth|session\.|cookies\(\))' "$f" 2>/dev/null; then
      protected=$((protected+1))
    else
      unprotected_list+=("$f")
    fi
  done < <(find app -name 'route.ts' -o -name 'route.js' 2>/dev/null)

  echo "Protegidos: $protected / $total"
  echo ""
  if [[ ${#unprotected_list[@]} -gt 0 ]]; then
    echo "❌ Sin auth detectada:"
    printf '  - %s\n' "${unprotected_list[@]}"
  fi
  echo ""

  echo "### Next.js Pages — páginas sin auth wrapper"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    grep -qE '(getServerSideProps|getStaticProps)' "$f" 2>/dev/null || continue
    grep -qE '(auth|session|requireAuth|redirect.*login)' "$f" 2>/dev/null \
      && echo "  ✅ $f" || echo "  ❌ $f"
  done < <(find pages -name '*.tsx' -o -name '*.ts' 2>/dev/null | grep -v '_app\|_document\|api/' | head -20)
  echo ""
fi

# ---- Laravel middleware ----
if [[ -d routes ]]; then
  echo "### Laravel — rutas sin middleware auth"
  for f in routes/api.php routes/web.php; do
    [[ -f "$f" ]] || continue
    echo "**$f:**"
    # rutas fuera de grupos con auth
    grep -n "Route::" "$f" 2>/dev/null | grep -v "middleware\s*=>\s*\[.*auth" | head -15 | sed 's/^/  /'
    echo ""
  done
fi

# ---- Middleware global ----
echo "### Middleware de auth global detectado"
for f in middleware.ts middleware.js src/middleware.ts app/middleware.ts; do
  [[ -f "$f" ]] && echo "  ✅ $f" && grep -E '(auth|session|redirect|matcher)' "$f" | head -5 | sed 's/^/    /'
done
echo ""

echo "### Resumen de imports de auth (archivos que usan auth)"
grep -rln $exclude --include='*.ts' --include='*.tsx' --include='*.js' \
  -E '(from.*auth|getSession|getServerSession|currentUser|requireAuth)' \
  . 2>/dev/null | grep -v 'node_modules' | head -20 | sed 's/^/- /'
