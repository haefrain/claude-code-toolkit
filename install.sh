#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║           Claude Code Toolkit — Instalador Ubuntu               ║
# ║  Ejecutar: bash install.sh                                       ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_LOCAL_BIN="$HOME/.local/bin"
BACKUP_DIR="$CLAUDE_DIR/backups/toolkit-install-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
fail() { echo -e "${RED}❌ $*${NC}"; exit 1; }
step() { echo -e "\n${BOLD}▶ $*${NC}"; }

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
    ok "$1 $(command -v "$1")"
  else
    warn "$1 no encontrado — instalando..."
    case "$1" in
      jq) sudo apt-get install -y jq >/dev/null 2>&1 && ok "jq instalado" || fail "No se pudo instalar jq. Corré: sudo apt install jq" ;;
      git) sudo apt-get install -y git >/dev/null 2>&1 && ok "git instalado" || fail "No se pudo instalar git" ;;
      gh)
        warn "GitHub CLI (gh) no encontrado."
        info "Instalando gh..."
        (type -p curl >/dev/null || sudo apt install curl -y) && \
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
        sudo apt update >/dev/null 2>&1 && sudo apt install gh -y >/dev/null 2>&1 && ok "gh instalado" || warn "gh no instalado — funcionalidad de issues limitada"
        ;;
      tree) sudo apt-get install -y tree >/dev/null 2>&1 && ok "tree instalado" || warn "tree no instalado (opcional)" ;;
    esac
  fi
}

check_cmd git
check_cmd jq
check_cmd gh
check_cmd tree

# ────────────────────────────────────────────────
# 2. BACKUP
# ────────────────────────────────────────────────
step "Creando backup de configuración existente"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  [[ -e "$1" ]] && cp -r "$1" "$BACKUP_DIR/" && info "Backup: $1" || true
}
backup_if_exists "$CLAUDE_DIR/settings.json"
backup_if_exists "$CLAUDE_DIR/CLAUDE.md"
backup_if_exists "$CLAUDE_DIR/commands"
backup_if_exists "$CLAUDE_DIR/scripts"
ok "Backup en $BACKUP_DIR"

# ────────────────────────────────────────────────
# 3. RTK — Rust Token Killer
# ────────────────────────────────────────────────
step "Instalando RTK (Rust Token Killer)"
mkdir -p "$CLAUDE_LOCAL_BIN"
cp "$REPO_DIR/bin/rtk" "$CLAUDE_LOCAL_BIN/rtk"
chmod +x "$CLAUDE_LOCAL_BIN/rtk"

# Agregar ~/.local/bin al PATH si no está
add_to_path() {
  local rc_file="$1"
  local export_line='export PATH="$HOME/.local/bin:$PATH"'
  if [[ -f "$rc_file" ]] && ! grep -q '\.local/bin' "$rc_file" 2>/dev/null; then
    echo "" >> "$rc_file"
    echo "# Claude Code Toolkit — RTK" >> "$rc_file"
    echo "$export_line" >> "$rc_file"
    info "PATH actualizado en $rc_file"
  fi
}
add_to_path "$HOME/.bashrc"
add_to_path "$HOME/.zshrc"
export PATH="$HOME/.local/bin:$PATH"

if rtk --version >/dev/null 2>&1; then
  ok "RTK instalado: $(rtk --version)"
else
  warn "RTK instalado pero no en PATH de esta sesión. Reabrí la terminal o corré: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ────────────────────────────────────────────────
# 4. SCRIPTS
# ────────────────────────────────────────────────
step "Instalando scripts (~/.claude/scripts/)"
mkdir -p "$CLAUDE_DIR/scripts"
cp "$REPO_DIR/scripts/"*.sh "$CLAUDE_DIR/scripts/"
chmod +x "$CLAUDE_DIR/scripts/"*.sh
ok "$(ls "$CLAUDE_DIR/scripts/"*.sh | wc -l) scripts instalados"

# ────────────────────────────────────────────────
# 5. SLASH COMMANDS
# ────────────────────────────────────────────────
step "Instalando slash commands (~/.claude/commands/)"
mkdir -p "$CLAUDE_DIR/commands"
cp "$REPO_DIR/commands/"*.md "$CLAUDE_DIR/commands/"
ok "$(ls "$CLAUDE_DIR/commands/"*.md | wc -l) comandos instalados"

# ────────────────────────────────────────────────
# 6. CLAUDE.MD — config global
# ────────────────────────────────────────────────
step "Instalando CLAUDE.md y archivos de referencia"

install_config() {
  local src="$REPO_DIR/config/$1"
  local dst="$CLAUDE_DIR/$1"
  if [[ -f "$dst" ]]; then
    warn "$1 ya existe. ¿Reemplazar? [s/N] "
    read -r -t 10 answer || answer="n"
    [[ "${answer,,}" == "s" ]] && cp "$src" "$dst" && ok "$1 reemplazado" || info "$1 conservado (backup en $BACKUP_DIR)"
  else
    cp "$src" "$dst"
    ok "$1 instalado"
  fi
}

# Los archivos de referencia siempre se instalan (no conflicto)
cp "$REPO_DIR/config/claude-issues.md" "$CLAUDE_DIR/claude-issues.md"
cp "$REPO_DIR/config/claude-toolkit.md" "$CLAUDE_DIR/claude-toolkit.md"
cp "$REPO_DIR/config/RTK.md" "$CLAUDE_DIR/RTK.md"
ok "Archivos de referencia instalados"

install_config "CLAUDE.md"

# ────────────────────────────────────────────────
# 7. SETTINGS.JSON — merge hooks + permisos
# ────────────────────────────────────────────────
step "Configurando settings.json"
SETTINGS="$CLAUDE_DIR/settings.json"

# Crear settings base si no existe
if [[ ! -f "$SETTINGS" ]]; then
  echo '{"$schema":"https://json.schemastore.org/claude-code-settings.json","permissions":{"allow":[],"deny":[]},"hooks":{}}' > "$SETTINGS"
  info "settings.json creado desde cero"
fi

# Permisos a agregar
SCRIPT_ALLOW=(
  'Bash(bash /home/'"$USER"'/.claude/scripts/*)'
  'Bash(bash -n /home/'"$USER"'/.claude/scripts/*)'
  'Bash(gh:*)'
  'Bash(git:*)'
  'Bash(jq:*)'
  'Bash(column:*)'
  'Bash(sort:*)'
  'Bash(uniq:*)'
  'Bash(wc:*)'
  'Bash(awk:*)'
  'Bash(sed:*)'
  'Bash(find:*)'
  'Bash(grep:*)'
  'Bash(basename:*)'
  'Bash(dirname:*)'
  'Bash(date:*)'
  'Bash(tr:*)'
  'Bash(head:*)'
  'Bash(tail:*)'
  'Bash(cut:*)'
  'Bash(cat:*)'
  'Bash(ls:*)'
  'Bash(mktemp:*)'
  'Bash(chmod:*)'
  'Bash(mkdir:*)'
  'Bash(cp:*)'
  'Bash(mv:*)'
  'Bash(ln:*)'
  'Bash(echo:*)'
  'Bash(printf:*)'
)

# Agregar permisos que no existen
tmp=$(mktemp)
current_allow=$(jq -r '.permissions.allow // []' "$SETTINGS")

new_allow="$current_allow"
for perm in "${SCRIPT_ALLOW[@]}"; do
  # Reemplazar $USER con el usuario real en el permiso de scripts
  perm="${perm/\$USER/$USER}"
  if ! echo "$current_allow" | jq -e --arg p "$perm" '.[] | select(. == $p)' >/dev/null 2>&1; then
    new_allow=$(echo "$new_allow" | jq --arg p "$perm" '. + [$p]')
  fi
done

# Merge hooks
HOOKS_JSON=$(cat << 'HOOKS'
{
  "SessionStart": [{"matcher": "startup", "hooks": [{"type": "command", "command": "bash ~/.claude/scripts/session-start-hook.sh"}]}],
  "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash ~/.claude/scripts/prompt-trigger-hook.sh"}]}],
  "PostToolUse": [{"matcher": "Edit|Write", "hooks": [{"type": "command", "command": "bash ~/.claude/scripts/post-tool-hook.sh"}]}],
  "Stop": [{"hooks": [{"type": "command", "command": "bash ~/.claude/scripts/stop-hook.sh"}]}]
}
HOOKS
)

# Fusionar con settings existentes preservando hooks del usuario
jq --argjson allow "$new_allow" \
   --argjson new_hooks "$HOOKS_JSON" \
   '.permissions.allow = $allow |
    .hooks = (.hooks // {}) * $new_hooks |
    .skipAutoPermissionPrompt = true' \
   "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

ok "settings.json actualizado (hooks + $(echo "${SCRIPT_ALLOW[@]}" | wc -w) permisos)"

# ────────────────────────────────────────────────
# 8. VERIFICACIÓN FINAL
# ────────────────────────────────────────────────
step "Verificación final"

checks_passed=0
checks_total=0

check() {
  local desc="$1"; local cmd="$2"
  checks_total=$((checks_total+1))
  if eval "$cmd" >/dev/null 2>&1; then
    ok "$desc"
    checks_passed=$((checks_passed+1))
  else
    warn "$desc — FALLÓ"
  fi
}

check "RTK binario ejecutable"          "rtk --version"
check "Scripts instalados"              "ls $CLAUDE_DIR/scripts/*.sh"
check "Slash commands instalados"       "ls $CLAUDE_DIR/commands/*.md"
check "CLAUDE.md existe"                "test -f $CLAUDE_DIR/CLAUDE.md"
check "claude-toolkit.md existe"        "test -f $CLAUDE_DIR/claude-toolkit.md"
check "settings.json válido"            "jq . $CLAUDE_DIR/settings.json"
check "Hook SessionStart configurado"   "jq -e '.hooks.SessionStart' $CLAUDE_DIR/settings.json"
check "Hook UserPromptSubmit config."   "jq -e '.hooks.UserPromptSubmit' $CLAUDE_DIR/settings.json"
check "Hook PostToolUse configurado"    "jq -e '.hooks.PostToolUse' $CLAUDE_DIR/settings.json"
check "Hook Stop configurado"           "jq -e '.hooks.Stop' $CLAUDE_DIR/settings.json"

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
echo "Próximos pasos:"
echo "  1. Reabrí tu terminal (o ejecutá: source ~/.bashrc)"
echo "  2. Abrí Claude Code en cualquier proyecto"
echo "  3. Los hooks se activan automáticamente"
echo ""
echo "Comandos rápidos para verificar:"
echo "  rtk --version                    # RTK funcionando"
echo "  rtk gain                         # Stats de ahorro de tokens"
echo "  ls ~/.claude/scripts/            # Scripts instalados"
echo "  ls ~/.claude/commands/           # Slash commands disponibles"
echo ""
echo "Backup de tu config anterior en:"
echo "  $BACKUP_DIR"
echo ""

if [[ $checks_passed -lt $checks_total ]]; then
  warn "Algunos checks fallaron. Revisá los mensajes ⚠️  arriba."
  exit 1
fi

ok "Todo listo. Reiniciá Claude Code para activar los hooks."
