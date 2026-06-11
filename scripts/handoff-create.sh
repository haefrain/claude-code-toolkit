#!/usr/bin/env bash
# handoff-create.sh — Genera un archivo de handoff al finalizar la sesión.
# Llamado desde stop-hook.sh (Stop hook de Claude Code). Funciona en cualquier repo git.
# Output: {repo}/.claude/handoff/YYYYMMDD-HHMM.md (excluido de git via .git/info/exclude)
set -euo pipefail

input=$(cat)
transcript=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null || echo "")

# ── Requiere estar en un repo git (cualquiera, no solo haefrain) ──
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "$git_root" ]] && exit 0

# ── Directorio de handoffs DENTRO del repo ─────────────────────
HANDOFF_DIR="$git_root/.claude/handoff"
mkdir -p "$HANDOFF_DIR"

# ── Excluir de git SIN tocar el .gitignore del proyecto ────────
# .git/info/exclude es un ignore local: git lo respeta pero no es un archivo del repo.
git_dir=$(git -C "$git_root" rev-parse --git-dir 2>/dev/null || true)
if [[ -n "$git_dir" ]]; then
  # git-dir puede ser relativo; normalizar
  [[ "$git_dir" != /* ]] && git_dir="$git_root/$git_dir"
  exclude_file="$git_dir/info/exclude"
  mkdir -p "$(dirname "$exclude_file")"
  if ! grep -qx '\.claude/handoff/' "$exclude_file" 2>/dev/null; then
    echo '.claude/handoff/' >> "$exclude_file"
  fi
fi

timestamp=$(date +%Y%m%d-%H%M)
handoff_file="$HANDOFF_DIR/${timestamp}.md"

# ── Recopilar información ──────────────────────────────────────
remote=$(git -C "$git_root" remote get-url origin 2>/dev/null || echo "(sin remote)")
branch=$(git -C "$git_root" branch --show-current 2>/dev/null || echo "unknown")

# 1. Archivos modificados (staged + unstaged)
modified_files=$(git -C "$git_root" diff --name-only HEAD 2>/dev/null | head -20 || true)
[[ -z "$modified_files" ]] && modified_files=$(git -C "$git_root" diff --name-only HEAD~1 2>/dev/null | head -20 || true)

# 2. Issues mencionados en el transcript
mentioned_issues=""
if [[ -n "$transcript" && -f "$transcript" ]]; then
  mentioned_issues=$(grep -oE '#[0-9]{2,4}' "$transcript" 2>/dev/null | sort -u | head -10 || true)
fi

# 3. Commits recientes de la sesión (últimas 2 horas; fallback: últimos 3)
recent_commits=$(git -C "$git_root" log --oneline --since="2 hours ago" --format="- %h %s" 2>/dev/null | head -10 || true)
[[ -z "$recent_commits" ]] && recent_commits=$(git -C "$git_root" log --oneline -3 --format="- %h %s" 2>/dev/null || true)

# ── Generar el archivo de handoff ─────────────────────────────
{
  echo "# Handoff — $(basename "$git_root") — ${timestamp}"
  echo ""
  echo "**Branch:** \`${branch}\`"
  echo "**Remote:** ${remote}"
  echo ""
  echo "## Lo que se trabajó esta sesión"
  echo ""
  if [[ -n "$recent_commits" ]]; then
    echo "**Commits recientes:**"
    echo "$recent_commits"
  else
    echo "_Sin commits en esta sesión_"
  fi
  echo ""
  echo "## Archivos modificados"
  echo ""
  if [[ -n "$modified_files" ]]; then
    echo "$modified_files" | sed 's/^/- /'
  else
    echo "_Sin cambios detectados en el working tree_"
  fi
  echo ""
  echo "## Issues trabajados"
  echo ""
  if [[ -n "$mentioned_issues" ]]; then
    echo "$mentioned_issues" | sed 's/^/- /'
  else
    echo "_No se mencionaron issues_"
  fi
  echo ""
  echo "## Próxima sesión"
  echo ""
  echo "1. Branch activo al cerrar: \`${branch}\`"
  echo "2. Revisá el backlog con \`/session-start\` o \`/backlog\`"
  echo "3. Si hay cambios sin commitear, revisá con \`/changes-summary\`"
  echo ""
  echo "---"
  echo "_Generado automáticamente por handoff-create.sh · ${timestamp}_"
} > "$handoff_file"

# ── Limpieza: retener solo los 10 handoffs más recientes ──────
ls -t "$HANDOFF_DIR"/*.md 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

echo "<!-- handoff-create: guardado en $handoff_file -->"
