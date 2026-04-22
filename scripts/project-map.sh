#!/usr/bin/env bash
# project-map.sh — mapa compacto de un proyecto para orientar a Claude sin gastar tokens
# explorando carpeta por carpeta.
# Uso: project-map.sh [path]  (default: .)
set -euo pipefail

path="${1:-.}"
cd "$path"
abs=$(pwd)

echo "# Project Map — $(basename "$abs")"
echo "*Path:* \`$abs\`"
echo ""

# ---- 1. Stack detection ----
stacks=()
[[ -f package.json ]] && stacks+=("Node/JS")
[[ -f next.config.js || -f next.config.ts || -f next.config.mjs ]] && stacks+=("Next.js")
[[ -f nuxt.config.ts || -f nuxt.config.js ]] && stacks+=("Nuxt")
[[ -f vite.config.ts || -f vite.config.js ]] && stacks+=("Vite")
[[ -f angular.json ]] && stacks+=("Angular")
[[ -f composer.json ]] && stacks+=("PHP/Composer")
[[ -f artisan ]] && stacks+=("Laravel")
[[ -f pubspec.yaml ]] && stacks+=("Dart/Flutter")
[[ -f pyproject.toml || -f requirements.txt ]] && stacks+=("Python")
[[ -f manage.py ]] && stacks+=("Django")
[[ -f Cargo.toml ]] && stacks+=("Rust")
[[ -f go.mod ]] && stacks+=("Go")
[[ -f Gemfile ]] && stacks+=("Ruby")
[[ -f pom.xml ]] && stacks+=("Java/Maven")
[[ -f build.gradle || -f build.gradle.kts ]] && stacks+=("Gradle")
[[ -f Dockerfile ]] && stacks+=("Docker")
[[ -f docker-compose.yml || -f docker-compose.yaml || -f compose.yml ]] && stacks+=("Compose")
[[ -f prisma/schema.prisma ]] && stacks+=("Prisma")
[[ -f drizzle.config.ts ]] && stacks+=("Drizzle")
[[ -d supabase ]] && stacks+=("Supabase")
[[ -f tailwind.config.js || -f tailwind.config.ts ]] && stacks+=("Tailwind")

echo "## Stack"
if [[ ${#stacks[@]} -eq 0 ]]; then
  echo "(no detectado)"
else
  printf '%s, ' "${stacks[@]}" | sed 's/, $//'
  echo ""
fi
echo ""

# ---- 2. Git info ----
if [[ -d .git ]]; then
  echo "## Git"
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  remote=$(git remote get-url origin 2>/dev/null || echo "(sin remote)")
  last=$(git log -1 --format="%h %cr — %s" 2>/dev/null || echo "(sin commits)")
  echo "- Branch: \`$branch\`"
  echo "- Remote: $remote"
  echo "- Último commit: $last"
  echo ""
fi

# ---- 3. package.json (name + scripts + deps) ----
if [[ -f package.json ]]; then
  echo "## package.json"
  name=$(jq -r '.name // "(sin nombre)"' package.json 2>/dev/null)
  ver=$(jq -r '.version // ""' package.json 2>/dev/null)
  echo "- **$name** $ver"

  scripts=$(jq -r '.scripts // {} | to_entries | .[] | "  - \(.key): \(.value)"' package.json 2>/dev/null | head -15)
  if [[ -n "$scripts" ]]; then
    echo "- Scripts:"
    echo "$scripts"
  fi

  echo "- Dependencias (top):"
  jq -r '.dependencies // {} | keys[]' package.json 2>/dev/null | head -15 | sed 's/^/  - /'

  echo "- DevDependencies (top):"
  jq -r '.devDependencies // {} | keys[]' package.json 2>/dev/null | head -10 | sed 's/^/  - /'
  echo ""
fi

# ---- 4. composer.json ----
if [[ -f composer.json ]]; then
  echo "## composer.json"
  jq -r '.name // "(sin nombre)"' composer.json 2>/dev/null | sed 's/^/- /'
  echo "- Requires:"
  jq -r '.require // {} | keys[]' composer.json 2>/dev/null | head -15 | sed 's/^/  - /'
  echo ""
fi

# ---- 5. pubspec.yaml ----
if [[ -f pubspec.yaml ]]; then
  echo "## pubspec.yaml"
  grep -E '^(name|version|description):' pubspec.yaml | head -3 | sed 's/^/- /'
  echo ""
fi

# ---- 6. Árbol top-level ----
echo "## Estructura (2 niveles, excluyendo noise)"
echo '```'
if command -v tree >/dev/null; then
  tree -L 2 -a \
    -I 'node_modules|.next|.nuxt|dist|build|.git|vendor|__pycache__|.venv|venv|.dart_tool|.idea|.vscode|target|.gradle|coverage|.turbo|.cache|ios/Pods|android/.gradle|.playwright-mcp|.claire|.claude|playwright-report|test-results|logs|tmp|.sentryclirc' \
    --dirsfirst --noreport 2>/dev/null | head -80
else
  # Fallback sin tree: find con depth
  find . -maxdepth 2 \
    -not -path '*/node_modules/*' \
    -not -path '*/.git/*' \
    -not -path '*/.next/*' \
    -not -path '*/vendor/*' \
    -not -path '*/dist/*' \
    -not -path '*/build/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/.venv/*' \
    2>/dev/null | head -60 | sed 's|^\./||'
fi
echo '```'
echo ""

# ---- 7. Routes auto-detectadas ----
echo "## Rutas / Endpoints detectados"
found_routes=0

# Next.js app router
if [[ -d app ]]; then
  routes=$(find app -type f \( -name 'route.ts' -o -name 'route.js' -o -name 'page.tsx' -o -name 'page.ts' \) 2>/dev/null | head -30)
  if [[ -n "$routes" ]]; then
    echo "### Next.js App Router"
    echo '```'
    echo "$routes" | sed 's|/route\.[tj]s$||; s|/page\.[tj]sx\?$||; s|^app||; s|^$|/|' | sort -u | head -30
    echo '```'
    found_routes=1
  fi
fi

# Next.js pages router
if [[ -d pages ]]; then
  echo "### Next.js Pages Router"
  echo '```'
  find pages -type f \( -name '*.tsx' -o -name '*.ts' -o -name '*.jsx' -o -name '*.js' \) 2>/dev/null \
    | head -30 | sed 's|^pages||; s|\.[tj]sx\?$||; s|/index$|/|'
  echo '```'
  found_routes=1
fi

# Laravel routes
if [[ -f routes/web.php || -f routes/api.php ]]; then
  echo "### Laravel Routes"
  echo '```'
  for f in routes/web.php routes/api.php routes/console.php; do
    [[ -f "$f" ]] && grep -hE "Route::(get|post|put|patch|delete|resource|apiResource)\(" "$f" 2>/dev/null | head -20 | sed "s|^|$f: |"
  done
  echo '```'
  found_routes=1
fi

# Express/Fastify routers (detección heurística)
express=$(grep -rE "(app|router)\.(get|post|put|patch|delete)\(['\"][/a-zA-Z]" \
  --include='*.ts' --include='*.js' \
  --exclude-dir=node_modules --exclude-dir=dist -l 2>/dev/null | head -5)
if [[ -n "$express" ]]; then
  echo "### Express/Fastify (archivos con rutas)"
  echo "$express" | sed 's/^/- /'
  found_routes=1
fi

# Django urls
if [[ -f urls.py ]] || find . -maxdepth 3 -name 'urls.py' -not -path '*/venv/*' -not -path '*/.venv/*' 2>/dev/null | head -1 | grep -q .; then
  echo "### Django URLs"
  find . -maxdepth 3 -name 'urls.py' -not -path '*/venv/*' -not -path '*/.venv/*' 2>/dev/null | head -10 | sed 's/^/- /'
  found_routes=1
fi

[[ $found_routes -eq 0 ]] && echo "(no se detectaron rutas automáticamente)"
echo ""

# ---- 8. Schema DB ----
if [[ -f prisma/schema.prisma ]]; then
  echo "## Prisma Schema"
  models=$(grep -E '^model ' prisma/schema.prisma | awk '{print $2}' | tr '\n' ', ' | sed 's/, $//')
  echo "- Modelos: $models"
  echo "- Migrations: $(find prisma/migrations -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
  echo ""
fi

if [[ -d database/migrations ]]; then
  echo "## Laravel Migrations"
  echo "- Count: $(find database/migrations -name '*.php' 2>/dev/null | wc -l)"
  echo ""
fi

# ---- 9. Archivos de config clave ----
echo "## Archivos de config clave"
configs=(
  ".env.example" "tsconfig.json" "tailwind.config.ts" "tailwind.config.js"
  "next.config.ts" "next.config.js" "next.config.mjs"
  "vite.config.ts" "nuxt.config.ts"
  "middleware.ts" "middleware.js"
  ".eslintrc.json" "biome.json" "eslint.config.js"
  "turbo.json" "pnpm-workspace.yaml"
  "Dockerfile" "docker-compose.yml" "compose.yml"
  "Makefile" "justfile"
)
for c in "${configs[@]}"; do
  [[ -f "$c" ]] && echo "- \`$c\`"
done
echo ""

# ---- 10. Quick stats ----
echo "## Stats"
if command -v rg >/dev/null; then
  for ext in ts tsx js jsx py php dart go rs; do
    count=$(rg --files --type-add "this:*.$ext" -t this 2>/dev/null | wc -l)
    [[ $count -gt 0 ]] && echo "- .$ext: $count archivos"
  done
fi
echo ""

echo "---"
echo "_Mapa generado por \`project-map.sh\`. Usá esto como índice; solo abre un archivo cuando lo necesites._"
