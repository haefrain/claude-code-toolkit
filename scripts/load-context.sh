#!/usr/bin/env bash
# load-context.sh — Carga contexto enriquecido al inicio de sesión.
# Llamado desde session-start-hook.sh (SessionStart hook). Funciona en cualquier repo git.
# Inyecta: handoff anterior + memorias del proyecto + codegraph + inventario de capacidades
# (slash commands, skills, agents y MCP servers del repo y globales) para que Claude
# aproveche todo el arsenal disponible.
set -euo pipefail

cwd="${CLAUDE_PROJECT_DIR:-${1:-$PWD}}"
git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)

# ── 1. Cargar handoff de la sesión anterior (desde el repo) ────
handoff_content=""
if [[ -n "$git_root" && -d "$git_root/.claude/handoff" ]]; then
  last_handoff=$(ls -t "$git_root/.claude/handoff"/*.md 2>/dev/null | head -1 || true)
  if [[ -n "$last_handoff" && -f "$last_handoff" ]]; then
    handoff_content=$(cat "$last_handoff")
  fi
fi

# ── 2. Cargar memorias del proyecto (globales de Claude Code) ──
memory_content=""
PROJECT_MEMORY_BASE="$HOME/.claude/projects"
if [[ -d "$PROJECT_MEMORY_BASE" ]]; then
  # Claude Code codifica el path reemplazando / y . por -: /Users/foo/bar → -Users-foo-bar
  encoded_path=$(echo "$cwd" | tr '/.' '--')
  memory_dir="$PROJECT_MEMORY_BASE/$encoded_path/memory"
  if [[ -d "$memory_dir" ]]; then
    while IFS= read -r mf; do
      [[ -f "$mf" ]] || continue
      desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "$mf" 2>/dev/null || true)
      [[ -n "$desc" ]] && memory_content="${memory_content}- ${desc}\n"
    done < <(ls "$memory_dir"/*.md 2>/dev/null || true)
  fi
fi

# ── 3. Consultar codegraph (solo si hay índice) ───────────────
codegraph_status=""
if command -v codegraph >/dev/null 2>&1 && [[ -n "$git_root" && -d "$git_root/.codegraph" ]]; then
  codegraph_status=$(codegraph status "$git_root" 2>/dev/null | head -8 || true)
fi

# ── 4. Inventario de capacidades ───────────────────────────────
# Repo-local: commands, skills, agents, MCP servers propios del proyecto.
# Global: plugins instalados + toolkit. Solo nombres — cero dumps.
capabilities=""

if [[ -n "$git_root" ]]; then
  # Slash commands del repo
  if [[ -d "$git_root/.claude/commands" ]]; then
    repo_cmds=$(ls "$git_root/.claude/commands"/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.md$//' | sed 's|^|/|' | tr '\n' ' ' || true)
    [[ -n "$repo_cmds" ]] && capabilities="${capabilities}- **Slash commands del repo:** ${repo_cmds}\n"
  fi
  # Skills del repo
  if [[ -d "$git_root/.claude/skills" ]]; then
    repo_skills=$(ls -d "$git_root/.claude/skills"/*/ 2>/dev/null | xargs -n1 basename 2>/dev/null | tr '\n' ' ' || true)
    [[ -n "$repo_skills" ]] && capabilities="${capabilities}- **Skills del repo:** ${repo_skills}\n"
  fi
  # Agents del repo
  if [[ -d "$git_root/.claude/agents" ]]; then
    repo_agents=$(ls "$git_root/.claude/agents"/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.md$//' | tr '\n' ' ' || true)
    [[ -n "$repo_agents" ]] && capabilities="${capabilities}- **Agents del repo:** ${repo_agents}\n"
  fi
  # MCP servers del repo
  if [[ -f "$git_root/.mcp.json" ]]; then
    repo_mcp=$(jq -r '.mcpServers // {} | keys | join(" ")' "$git_root/.mcp.json" 2>/dev/null || true)
    [[ -n "$repo_mcp" ]] && capabilities="${capabilities}- **MCP servers del repo (.mcp.json):** ${repo_mcp}\n"
  fi
fi

# Plugins globales instalados
if [[ -f "$HOME/.claude/plugins/installed_plugins.json" ]]; then
  global_plugins=$(jq -r '.plugins // {} | keys | map(split("@")[0]) | unique | join(" ")' \
    "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null || true)
  [[ -n "$global_plugins" ]] && capabilities="${capabilities}- **Plugins globales:** ${global_plugins}\n"
fi

# Toolkit global (commands + scripts)
toolkit_cmd_count=$( (ls "$HOME/.claude/commands"/*.md 2>/dev/null || true) | wc -l | xargs)
toolkit_script_count=$( (ls "$HOME/.claude/scripts"/*.sh 2>/dev/null || true) | wc -l | xargs)
if [[ "$toolkit_cmd_count" -gt 0 || "$toolkit_script_count" -gt 0 ]]; then
  capabilities="${capabilities}- **Toolkit global:** ${toolkit_cmd_count} slash commands + ${toolkit_script_count} scripts (\`~/.claude/scripts/\` — ver claude-toolkit.md para disparadores)\n"
fi

# CodeGraph disponible pero sin índice → sugerir inicializar
if command -v codegraph >/dev/null 2>&1 && [[ -n "$git_root" && ! -d "$git_root/.codegraph" ]]; then
  capabilities="${capabilities}- **CodeGraph:** disponible pero SIN índice en este repo — sugerí \`/codegraph-init\` al usuario si la sesión es de desarrollo\n"
fi

# ── Salir en silencio si no hay nada que inyectar ─────────────
if [[ -z "$handoff_content" && -z "$memory_content" && -z "$codegraph_status" && -z "$capabilities" ]]; then
  exit 0
fi

# ── Emitir el contexto enriquecido ─────────────────────────────
echo "<!-- load-context: contexto enriquecido cargado -->"
echo ""

if [[ -n "$handoff_content" ]]; then
  echo "## Continuación de sesión anterior"
  echo ""
  echo "$handoff_content"
  echo ""
  echo "---"
  echo ""
fi

if [[ -n "$memory_content" ]]; then
  echo "## Memorias del proyecto"
  echo ""
  printf "%b" "$memory_content"
  echo ""
  echo "---"
  echo ""
fi

if [[ -n "$codegraph_status" ]]; then
  echo "## CodeGraph: índice disponible"
  echo ""
  echo "$codegraph_status"
  echo ""
  echo "Usá las tools MCP de codegraph (codegraph_context, codegraph_search, codegraph_trace) ANTES de grep/read manual."
  echo ""
  echo "---"
  echo ""
fi

if [[ -n "$capabilities" ]]; then
  echo "## Capacidades disponibles en esta sesión"
  echo ""
  printf "%b" "$capabilities"
  echo ""
  echo "**Regla:** usá siempre la herramienta más específica disponible (script del toolkit > comando crudo; codegraph > grep manual; skill > improvisación)."
  echo ""
fi
