#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║      Claude Code Toolkit — Instalador macOS / Ubuntu / WSL2     ║
# ║  Ejecutar: bash install.sh                                       ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Seguro con configuraciones pre-existentes:
#   - Backup automático antes de tocar nada
#   - CLAUDE.md: opción reemplazar / mergear / conservar
#   - settings.json: hooks se APPENDEAN (no reemplazan) si ya existen
#   - Permisos: solo se agregan los que faltan, nunca se eliminan
#   - Scripts/commands: solo sobreescribe los del toolkit (los tuyos propios se conservan)
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/toolkit-install-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
fail() { echo -e "${RED}❌ $*${NC}"; exit 1; }
step() { echo -e "\n${BOLD}▶ $*${NC}"; }

# ── Detección de OS ──────────────────────────────────────────────
OS_TYPE="linux"
[[ "$(uname -s)" == "Darwin" ]] && OS_TYPE="macos"

pkg_install() {
  local pkg="$1"
  if [[ "$OS_TYPE" == "macos" ]]; then
    if command -v brew >/dev/null 2>&1; then
      brew install "$pkg" >/dev/null 2>&1 && ok "$pkg instalado (brew)" \
        || warn "brew install $pkg falló — instalalo manualmente: brew install $pkg"
    else
      fail "Homebrew no encontrado. Instalalo en https://brew.sh y volvé a ejecutar install.sh"
    fi
  else
    sudo apt-get install -y "$pkg" >/dev/null 2>&1 && ok "$pkg instalado" \
      || fail "No se pudo instalar $pkg. Corré: sudo apt install $pkg"
  fi
}

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Claude Code Toolkit — Instalador                  ║"
echo "║  Scripts + Comandos + RTK + Hooks + Permisos                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ────────────────────────────────────────────────
# 1. PREREQS
# ────────────────────────────────────────────────
step "Verificando prerequisitos"

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 ($(command -v "$1"))"
  else
    warn "$1 no encontrado — instalando..."
    case "$1" in
      jq|git|tree)
        pkg_install "$1" || true
        ;;
      gh)
        if [[ "$OS_TYPE" == "macos" ]]; then
          pkg_install "gh" || warn "gh no instalado — funcionalidad de issues/PRs limitada"
          return 0
        fi
        info "Instalando GitHub CLI (gh) via apt..."
        (type -p curl >/dev/null || sudo apt install curl -y) \
        && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
           | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
        && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
           | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update >/dev/null 2>&1 \
        && sudo apt install gh -y >/dev/null 2>&1 \
        && ok "gh instalado" \
        || warn "gh no instalado — funcionalidad de issues/PRs limitada"
        ;;
    esac
  fi
}

check_cmd git
check_cmd jq
check_cmd gh
check_cmd tree

# ────────────────────────────────────────────────
# 2. BACKUP (siempre, antes de tocar nada)
# ────────────────────────────────────────────────
step "Creando backup de configuración existente"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  if [[ -e "$1" ]]; then
    cp -rL "$1" "$BACKUP_DIR/" 2>/dev/null && info "Backup: $1" || true
  fi
}
backup_if_exists "$CLAUDE_DIR/settings.json"
backup_if_exists "$CLAUDE_DIR/CLAUDE.md"
backup_if_exists "$CLAUDE_DIR/commands"
backup_if_exists "$CLAUDE_DIR/scripts"
ok "Backup guardado en $BACKUP_DIR"

# ────────────────────────────────────────────────
# 3. RTK — Rust Token Killer
# ────────────────────────────────────────────────
step "Instalando RTK (Rust Token Killer)"

if rtk --version >/dev/null 2>&1; then
  ok "RTK ya instalado: $(rtk --version)"
else
  if ! command -v curl >/dev/null 2>&1; then
    fail "curl no encontrado — instalalo con: sudo apt install curl"
  fi
  if ! curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh; then
    if [[ "$OS_TYPE" == "macos" ]]; then
      warn "RTK no se pudo instalar en macOS — el resto del toolkit funciona sin RTK"
    else
      fail "No se pudo instalar RTK. Intentá manualmente: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
    fi
  fi
  export PATH="$HOME/.local/bin:$PATH"
  if rtk --version >/dev/null 2>&1; then
    ok "RTK instalado: $(rtk --version)"
  else
    warn "RTK instalado pero requiere nueva terminal."
  fi
fi

info "Inicializando RTK con configuración global..."
rtk init --global || warn "rtk init --global falló — podés correrlo manualmente después"

# ────────────────────────────────────────────────
# 4. SCRIPTS (solo sobreescribe los del toolkit)
# ────────────────────────────────────────────────
step "Instalando scripts (~/.claude/scripts/)"
mkdir -p "$CLAUDE_DIR/scripts"
cp "$REPO_DIR/scripts/"*.sh "$CLAUDE_DIR/scripts/"
chmod +x "$CLAUDE_DIR/scripts/"*.sh
ok "$(ls "$CLAUDE_DIR/scripts/"*.sh | wc -l) scripts instalados (tus scripts custom con otros nombres se conservan)"

# ────────────────────────────────────────────────
# 5. SLASH COMMANDS (solo sobreescribe los del toolkit)
# ────────────────────────────────────────────────
step "Instalando slash commands (~/.claude/commands/)"
mkdir -p "$CLAUDE_DIR/commands"
cp "$REPO_DIR/commands/"*.md "$CLAUDE_DIR/commands/"
ok "$(ls "$CLAUDE_DIR/commands/"*.md | wc -l) comandos instalados (los tuyos con otros nombres se conservan)"

# Plantillas de contrato de verificación (Sección 01)
mkdir -p "$CLAUDE_DIR/templates/verify"
cp "$REPO_DIR/config/templates/verify/"*.sh "$CLAUDE_DIR/templates/verify/"
chmod +x "$CLAUDE_DIR/templates/verify/"*.sh
ok "$(ls "$CLAUDE_DIR/templates/verify/"*.sh | wc -l | xargs) plantillas de verificación instaladas"

# ────────────────────────────────────────────────
# 6. CLAUDE.MD — merge inteligente
# ────────────────────────────────────────────────
step "Configurando CLAUDE.md"

# Los archivos de referencia siempre se instalan (no hay conflicto posible)
cp "$REPO_DIR/config/claude-issues.md"  "$CLAUDE_DIR/claude-issues.md"
cp "$REPO_DIR/config/claude-toolkit.md" "$CLAUDE_DIR/claude-toolkit.md"
cp "$REPO_DIR/config/RTK.md"            "$CLAUDE_DIR/RTK.md"
cp "$REPO_DIR/config/claude-verification.md" "$CLAUDE_DIR/claude-verification.md"
ok "Archivos de referencia instalados (claude-issues.md, claude-toolkit.md, RTK.md, claude-verification.md)"

CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
TOOLKIT_IMPORTS="@claude-issues.md
@claude-toolkit.md
@claude-verification.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  # Instalación limpia: copiar directo
  cp "$REPO_DIR/config/CLAUDE.md" "$CLAUDE_MD"
  ok "CLAUDE.md instalado (limpio)"

elif grep -q "@claude-toolkit.md" "$CLAUDE_MD" 2>/dev/null; then
  # Ya tiene nuestros imports: actualizar solo los archivos de referencia (ya hecho arriba)
  info "CLAUDE.md ya tiene los @imports del toolkit — sin cambios en CLAUDE.md"

else
  # CLAUDE.md pre-existente sin nuestros imports: preguntar
  echo ""
  echo -e "${YELLOW}CLAUDE.md pre-existente detectado. ¿Qué hacer?${NC}"
  echo "  [1] Mergear  — agregar @imports al final de tu CLAUDE.md (recomendado)"
  echo "  [2] Reemplazar — instalar el CLAUDE.md del toolkit (tu contenido se pierde)"
  echo "  [3] Conservar  — no tocar tu CLAUDE.md (los scripts funcionan igual, sin CLAUDE.md del toolkit)"
  echo ""
  printf "Opción [1/2/3, default=1]: "
  read -r -t 30 claude_opt || claude_opt="1"
  claude_opt="${claude_opt:-1}"

  case "$claude_opt" in
    2)
      cp "$REPO_DIR/config/CLAUDE.md" "$CLAUDE_MD"
      ok "CLAUDE.md reemplazado (backup en $BACKUP_DIR)"
      ;;
    3)
      info "CLAUDE.md conservado sin cambios."
      warn "Los archivos claude-issues.md y claude-toolkit.md están instalados pero no referenciados."
      warn "Para activarlos, agregá al final de tu CLAUDE.md:"
      echo "  @claude-issues.md"
      echo "  @claude-toolkit.md"
      echo "  @claude-verification.md"
      ;;
    *)  # 1 o cualquier otra cosa
      # Agregar @imports al final si no existen ya
      {
        echo ""
        echo "# ── Claude Code Toolkit (auto-instalado) ──"
        echo "@claude-issues.md"
        echo "@claude-toolkit.md"
        echo "@claude-verification.md"
      } >> "$CLAUDE_MD"
      ok "CLAUDE.md mergeado — @imports agregados al final de tu configuración existente"
      ;;
  esac
fi

# Instalaciones previas del toolkit: agregar el import de verificación si falta
if [[ -f "$CLAUDE_MD" ]] && grep -q "@claude-toolkit.md" "$CLAUDE_MD" && ! grep -q "@claude-verification.md" "$CLAUDE_MD"; then
  printf '\n@claude-verification.md\n' >> "$CLAUDE_MD"
  ok "Import @claude-verification.md agregado a CLAUDE.md existente"
fi

# ────────────────────────────────────────────────
# 7. SETTINGS.JSON — merge seguro (append, nunca reemplaza)
# ────────────────────────────────────────────────
step "Configurando settings.json"
SETTINGS="$CLAUDE_DIR/settings.json"

# Crear settings base si no existe
if [[ ! -f "$SETTINGS" ]]; then
  echo '{"$schema":"https://json.schemastore.org/claude-code-settings.json","permissions":{"allow":[],"deny":[]},"hooks":{}}' > "$SETTINGS"
  info "settings.json creado desde cero"
fi

# ── 7a. Permisos: solo agregar los que faltan ──
SCRIPT_ALLOW=(
  "Bash(bash $HOME/.claude/scripts/*)"
  "Bash(bash -n $HOME/.claude/scripts/*)"
  'Bash(gh:*)'   'Bash(git:*)'    'Bash(jq:*)'     'Bash(column:*)'
  'Bash(sort:*)' 'Bash(uniq:*)'   'Bash(wc:*)'     'Bash(awk:*)'
  'Bash(sed:*)'  'Bash(find:*)'   'Bash(grep:*)'   'Bash(basename:*)'
  'Bash(dirname:*)' 'Bash(date:*)' 'Bash(tr:*)'    'Bash(head:*)'
  'Bash(tail:*)' 'Bash(cut:*)'    'Bash(cat:*)'    'Bash(ls:*)'
  'Bash(mktemp:*)' 'Bash(chmod:*)' 'Bash(mkdir:*)' 'Bash(cp:*)'
  'Bash(mv:*)'   'Bash(ln:*)'     'Bash(echo:*)'   'Bash(printf:*)'
)

tmp=$(mktemp)
current_allow=$(jq '.permissions.allow // []' "$SETTINGS")
new_allow="$current_allow"
added_perms=0
for perm in "${SCRIPT_ALLOW[@]}"; do
  if ! echo "$current_allow" | jq -e --arg p "$perm" 'any(. == $p)' >/dev/null 2>&1; then
    new_allow=$(echo "$new_allow" | jq --arg p "$perm" '. + [$p]')
    added_perms=$((added_perms+1))
  fi
done
[[ $added_perms -gt 0 ]] && ok "$added_perms permisos nuevos agregados" || info "Todos los permisos ya estaban presentes"

# ── 7b. Hooks: append-only por evento (nunca reemplaza hooks existentes) ──
# Por cada evento, verificamos si ya hay un entry con nuestro comando.
# Si no está, lo agregamos. Si ya está (reinstalación), lo saltamos.
# Nota: se evita declare -A para compatibilidad con bash y zsh.

_append_hook() {
  local event="$1" entry="$2"
  local our_cmd already_present
  our_cmd=$(printf '%s' "$entry" | jq -r '.. | .command? // empty' | head -1)
  already_present=$(printf '%s' "$current_settings" | jq --arg evt "$event" --arg cmd "$our_cmd" \
    '(.hooks[$evt] // []) | any(.. | .command? == $cmd)' 2>/dev/null || printf 'false')
  if [[ "$already_present" == "true" ]]; then
    info "Hook $event ya configurado — sin cambios"
  else
    current_settings=$(printf '%s' "$current_settings" | jq \
      --arg evt "$event" \
      --argjson entry "$entry" \
      '.hooks[$evt] = (.hooks[$evt] // []) + [$entry]')
    ok "Hook $event agregado"
  fi
}

current_settings=$(cat "$SETTINGS")
_append_hook "SessionStart"      '{"matcher":"startup","hooks":[{"type":"command","command":"bash ~/.claude/scripts/session-start-hook.sh"}]}'
_append_hook "UserPromptSubmit"  '{"hooks":[{"type":"command","command":"bash ~/.claude/scripts/prompt-trigger-hook.sh"}]}'
_append_hook "PostToolUse"       '{"matcher":"Edit|Write","hooks":[{"type":"command","command":"bash ~/.claude/scripts/post-tool-hook.sh"}]}'
_append_hook "Stop"              '{"hooks":[{"type":"command","command":"bash ~/.claude/scripts/stop-hook.sh"}]}'
# La verificación puede correr lint/tests: subir el timeout del Stop hook a 600s (idempotente)
current_settings=$(printf '%s' "$current_settings" | jq \
  '(.hooks.Stop // []) |= map(
     .hooks |= map(if .command == "bash ~/.claude/scripts/stop-hook.sh" then . + {timeout: 600} else . end)
   )')
# RTK PreToolUse: rtk init --global lo deja como "manual step" en modo no-interactivo — lo registramos acá
command -v rtk >/dev/null 2>&1 && \
_append_hook "PreToolUse"        '{"matcher":"Bash","hooks":[{"type":"command","command":"rtk hook claude"}]}'

# ── 7c. Escribir settings final ──
echo "$current_settings" \
  | jq --argjson allow "$new_allow" \
       '.permissions.allow = $allow | .skipAutoPermissionPrompt = true' \
  > "$tmp" && mv "$tmp" "$SETTINGS"

jq . "$SETTINGS" > /dev/null && ok "settings.json actualizado y válido" || fail "settings.json resultó inválido — restaurá desde $BACKUP_DIR"

# ────────────────────────────────────────────────
# 8. CODEGRAPH MCP SERVER
# ────────────────────────────────────────────────
step "Configurando CodeGraph MCP"

if command -v codegraph >/dev/null 2>&1; then
  ok "codegraph ya instalado: $(codegraph --version)"
else
  if command -v npm >/dev/null 2>&1; then
    info "Instalando codegraph via npm..."
    # Versión pineada (auditada) — actualizar deliberadamente, no a ciegas
    npm install -g @colbymchenry/codegraph@0.9.7 >/dev/null 2>&1 \
      && ok "codegraph instalado: $(codegraph --version 2>/dev/null || echo 'ok')" \
      || warn "npm install de codegraph falló — instalalo manualmente: npm install -g @colbymchenry/codegraph@0.9.7"
  else
    warn "npm no encontrado — instalá Node.js y luego: npm install -g @colbymchenry/codegraph"
  fi
fi

if command -v codegraph >/dev/null 2>&1; then
  info "Registrando codegraph como MCP server en Claude Code..."
  # El target id de Claude Code en codegraph es "claude" (no "claude-code")
  codegraph install --target=claude --location=global -y \
    && ok "CodeGraph MCP configurado en Claude Code" \
    || warn "codegraph install falló — corré manualmente: codegraph install --target=claude --location=global -y"
fi

# ────────────────────────────────────────────────
# 9. VERIFICACIÓN FINAL
# ────────────────────────────────────────────────
step "Verificación final"

checks_passed=0; checks_total=0
check() {
  local desc="$1" cmd="$2"
  checks_total=$((checks_total+1))
  if eval "$cmd" >/dev/null 2>&1; then
    ok "$desc"; checks_passed=$((checks_passed+1))
  else
    warn "$desc — FALLÓ"
  fi
}

check "RTK binario ejecutable"         "rtk --version"
check "Scripts instalados"             "ls $CLAUDE_DIR/scripts/*.sh"
check "Slash commands instalados"      "ls $CLAUDE_DIR/commands/*.md"
check "CLAUDE.md existe"               "test -f $CLAUDE_DIR/CLAUDE.md"
check "claude-toolkit.md existe"       "test -f $CLAUDE_DIR/claude-toolkit.md"
check "claude-issues.md existe"        "test -f $CLAUDE_DIR/claude-issues.md"
check "settings.json válido"           "jq . $CLAUDE_DIR/settings.json"
check "Hook SessionStart configurado"  "jq -e '.hooks.SessionStart' $CLAUDE_DIR/settings.json"
check "Hook UserPromptSubmit config."  "jq -e '.hooks.UserPromptSubmit' $CLAUDE_DIR/settings.json"
check "Hook PostToolUse configurado"   "jq -e '.hooks.PostToolUse' $CLAUDE_DIR/settings.json"
check "Hook Stop configurado"          "jq -e '.hooks.Stop' $CLAUDE_DIR/settings.json"
check "Hook PreToolUse (RTK) config."  "jq -e '.hooks.PreToolUse' $CLAUDE_DIR/settings.json"
check "CodeGraph instalado"            "codegraph --version"
check "CodeGraph MCP registrado"       "jq -e '.mcpServers.codegraph' $HOME/.claude.json"
check "Script handoff-create presente" "test -x $CLAUDE_DIR/scripts/handoff-create.sh"
check "Script load-context presente"   "test -x $CLAUDE_DIR/scripts/load-context.sh"

echo ""
echo -e "${BOLD}Resultado: $checks_passed/$checks_total checks pasados${NC}"

# ────────────────────────────────────────────────
# RESUMEN
# ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  Instalación completa                                        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
_shell_rc="$HOME/.bashrc"
[[ "$(basename "${SHELL:-bash}")" == "zsh" ]] && _shell_rc="$HOME/.zshrc"

echo "Próximos pasos:"
echo "  1. Reabrí tu terminal (o ejecutá: source $_shell_rc)"
echo "  2. Abrí Claude Code en cualquier proyecto"
echo "  3. Los hooks se activan automáticamente"
echo ""
echo "Verificación rápida:"
echo "  rtk --version            # RTK funcionando"
echo "  rtk gain                 # stats de ahorro de tokens"
echo "  ls ~/.claude/scripts/    # 26 scripts disponibles"
echo "  ls ~/.claude/commands/   # 28 slash commands (/map, /backlog, /handoff, etc.)"
echo "  codegraph --version      # CodeGraph MCP funcionando"
echo ""
echo "Backup de tu config anterior en: $BACKUP_DIR"
echo ""

if [[ $checks_passed -lt $checks_total ]]; then
  warn "Algunos checks fallaron. Para restaurar: cp -r $BACKUP_DIR/* $CLAUDE_DIR/"
  exit 1
fi

ok "Todo listo. Reiniciá Claude Code para activar los hooks."
