---
description: Bootstrapea el contrato de verificación .claude/verify.sh del repo actual desde la plantilla del stack detectado.
argument-hint: ""
---

Crea el contrato de verificación del repo actual. Seguí estos pasos EXACTOS:

## 1. Detectar el stack (no asumas — verificá archivos)

```bash
root=$(git rev-parse --show-toplevel) && { ls "$root/package.json" "$root/composer.json" "$root/Gemfile" "$root/artisan" 2>/dev/null; ls "$root"/pnpm-lock.yaml "$root"/yarn.lock "$root"/bun.lock* "$root"/package-lock.json 2>/dev/null; }
```

Precedencia determinista — el primero que matchee gana:

1. `artisan` + `composer.json` → plantilla `laravel.sh`. **Si además hay `package.json` con scripts `lint`/`typecheck`/`build` reales, agregá esos comandos del frontend al contrato** (leyendo los scripts reales — la regla de nunca inventar sigue aplicando).
2. Si no, `package.json` → plantilla `node.sh` (PM según lockfile: pnpm-lock.yaml→`pnpm`, yarn.lock→`yarn`, bun.lock*→`bun run`, package-lock.json→`npm run`)
3. Si no, `Gemfile` → plantilla `rails.sh`
4. Ninguno → plantilla `generic.sh`

## 2. Leer los scripts REALES del repo

Lee `package.json` (campo `scripts`) o `composer.json` (campo `scripts`) o los binstubs/gems disponibles. El contrato SOLO puede invocar comandos que existen — jamás inventes un script.

## 3. Generar el contrato

```bash
mkdir -p "$root/.claude" && cp ~/.claude/templates/verify/<plantilla> "$root/.claude/verify.sh" && chmod +x "$root/.claude/verify.sh"
```

Luego EDITÁ `.claude/verify.sh` reemplazando los comandos de la plantilla por los reales detectados en el paso 2:
- **Modo rápido** (siempre corre, presupuesto < 5 min): lint + typecheck + tests enfocados si son baratos.
- **Bloque `FULL=1`**: suite completa + build.

**Nivel MUTATION:** si el repo tiene config de mutation testing (`infection.json5`/`infection.json`, `stryker.conf.*`, `.mutant.yml`), dejá el bloque `MUTATION=1` de la plantilla con el comando real del repo. Si no la tiene, dejá el bloque como viene (la herramienta del stack queda sugerida) y mencionale a Efraín que existe: mide que los tests maten mutantes (MSI), no que solo pasen. En repos multi-stack (p. ej. Laravel o Rails con frontend JS/TS), el bloque `MUTATION=1` combina herramientas: Infection/mutant para el backend + Stryker para el frontend — cada una sobre su suite.

## 4. Política de versionado

```bash
git -C "$root" remote get-url origin
```

- Remote `github.com/haefrain/*` → agregá el archivo a git: `git -C "$root" add .claude/verify.sh` y sugerí comitearlo.
- Remote ajeno (bukhr/*, etc.) → NO lo comitees, agregalo al exclude local (`--git-path` resuelve la ruta correcta tanto en repos normales como en worktrees, donde `.git` es un archivo, no un directorio):

```bash
exclude_file=$(git -C "$root" rev-parse --git-path info/exclude)
[[ "$exclude_file" = /* ]] || exclude_file="$root/$exclude_file"
grep -qxF ".claude/verify.sh" "$exclude_file" 2>/dev/null || echo ".claude/verify.sh" >> "$exclude_file"
```

- Sin remote `origin` (repo solo local) → tratalo como ajeno (exclude local) y pregúntale a Efraín si debería comitearse.

## 5. Validar

1. Corré el contrato: `bash "$root/.claude/verify.sh"` — debe terminar en exit 0 sobre el repo limpio. Si falla por comandos inexistentes, corregí el contrato (no el repo).
2. Mostrale a Efraín el contrato final y qué política de versionado se aplicó.
3. Recordá: a partir de ahora el hook Stop correrá este contrato cuando haya código editado; si falla, Claude sigue trabajando en vez de entregar.
