---
description: Bootstrapea SDD Buk (Spec Kit + overlay) en el repo actual — constitution, overrides, plantillas y reglas del agente, con política por propietario del repo.
argument-hint: ""
---

Inicializa el SDD Buk en el repo actual. Pasos EXACTOS:

## 1. Prerrequisito: specify CLI

```bash
command -v specify >/dev/null && specify --help >/dev/null 2>&1 && echo OK || echo "FALTA"
```

Si FALTA: avisale a Efraín — instalación manual: `uv tool install specify-cli` (requiere [uv](https://docs.astral.sh/uv/)). **NO continúes sin specify.**

## 2. Inicializar Spec Kit (si el repo no lo tiene)

```bash
root=$(git rev-parse --show-toplevel) && { [[ -d "$root/.specify" ]] && echo "ya inicializado" || (cd "$root" && specify init --here --integration claude-code); }
```

(Si tu versión usa otro nombre de integración, `specify init --help` lo lista.)

## 3. Aplicar el overlay Buk (desde las plantillas globales del toolkit)

```bash
mkdir -p "$root/.specify/templates/overrides" "$root/docs"
cp ~/.claude/templates/buk-speckit/constitution.md "$root/.specify/memory/constitution.md"
cp ~/.claude/templates/buk-speckit/overrides/*.md "$root/.specify/templates/overrides/"
cp -r ~/.claude/templates/buk-speckit/plantillas "$root/docs/"
```

## 4. Reglas del agente — política por propietario del repo

```bash
git -C "$root" remote get-url origin 2>/dev/null || echo "SIN-REMOTE"
```

- **Remote `github.com/haefrain/*`** → añadí el bloque de `~/.claude/templates/buk-speckit/CLAUDE.buk.md` al final del `CLAUDE.md` del repo (solo si no tiene ya los marcadores `BUK-SPECKIT:INICIO/FIN`) y sugerí comitear todo (`.specify/`, `docs/plantillas/`, `CLAUDE.md`).
- **Remote ajeno (bukhr/*, etc.) o SIN-REMOTE** → NADA se comitea ni se toca el CLAUDE.md del equipo: añadí el bloque a `CLAUDE.local.md` (crealo si no existe) y metélo todo al exclude local:

```bash
exclude_file=$(git -C "$root" rev-parse --git-path info/exclude)
[[ "$exclude_file" = /* ]] || exclude_file="$root/$exclude_file"
for p in .specify/ docs/plantillas/ docs/tracks/ specs/ CLAUDE.local.md; do
  grep -qxF "$p" "$exclude_file" 2>/dev/null || echo "$p" >> "$exclude_file"
done
```

## 5. Cierre

1. Sugerí correr: `/speckit.constitution Revisa .specify/memory/constitution.md, ajústala a este repo y confírmala`.
2. Si el repo no tiene `.claude/verify.sh`, sugerí `/verify-setup` — la constitution IV (verificación como gate) lo asume.
3. Mostrale a Efraín qué quedó instalado y qué política de versionado se aplicó.
