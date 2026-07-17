#!/bin/bash
# ~/.claude/scripts/statusline.sh
#
# Status line de Claude Code para Efraín. Compatible con bash 3.2 (macOS).
# Lee el JSON de estado por stdin y arma una sola línea compacta:
#   ⏵ <modelo> · <directorio> (<rama>) · ctx <restante>% · $<costo>
#
# Debe salir SIEMPRE con código 0 y degradar con gracia si falta algún campo.

input="$(cat 2>/dev/null)"
[ -z "$input" ] && input='{}'

# Extrae un valor con jq; si jq falla o el campo no existe, devuelve cadena vacía.
jget() {
  printf '%s' "$input" | jq -r "$1" 2>/dev/null
}

# --- Modelo ---
model_name="$(jget '.model.display_name // .model.id // empty')"
: "${model_name:=?}"

# --- Directorio actual (basename) ---
cwd="$(jget '.workspace.current_dir // .cwd // empty')"
if [ -z "$cwd" ]; then
  cwd="$(pwd 2>/dev/null)"
fi
dir_name="$(basename "$cwd" 2>/dev/null)"
: "${dir_name:=?}"

# --- Rama git: lectura directa de .git/HEAD (sin invocar git, barato) ---
find_git_entry() {
  local dir="$1"
  local i=0
  while [ -n "$dir" ] && [ "$dir" != "/" ] && [ "$i" -lt 30 ]; do
    if [ -e "$dir/.git" ]; then
      printf '%s' "$dir/.git"
      return 0
    fi
    dir="$(dirname "$dir" 2>/dev/null)"
    i=$((i + 1))
  done
  return 1
}

branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  git_entry="$(find_git_entry "$cwd" 2>/dev/null)"
  if [ -n "$git_entry" ]; then
    if [ -f "$git_entry" ]; then
      # Worktree: .git es un archivo "gitdir: <ruta>"
      gitdir_line="$(cat "$git_entry" 2>/dev/null)"
      real_git_dir="${gitdir_line#gitdir: }"
      case "$real_git_dir" in
        /*) : ;;
        *) real_git_dir="$(dirname "$git_entry")/$real_git_dir" ;;
      esac
      head_file="$real_git_dir/HEAD"
    else
      head_file="$git_entry/HEAD"
    fi
    if [ -f "$head_file" ]; then
      head_content="$(cat "$head_file" 2>/dev/null)"
      case "$head_content" in
        ref:*)
          branch="${head_content#ref: refs/heads/}"
          ;;
        *)
          # HEAD detached: muestra el sha corto
          branch="${head_content%%[$'\n\r']*}"
          branch="${branch:0:7}"
          ;;
      esac
    fi
  fi
fi

# --- Contexto restante (%) ---
ctx_display=""
ctx_remaining="$(jget '.context_window.remaining_percentage // empty')"
if [ -n "$ctx_remaining" ]; then
  ctx_display="$(printf '%.0f' "$ctx_remaining" 2>/dev/null)"
else
  ctx_used="$(jget '.context_window.used_percentage // empty')"
  if [ -n "$ctx_used" ]; then
    ctx_used_int="$(printf '%.0f' "$ctx_used" 2>/dev/null)"
    [ -n "$ctx_used_int" ] && ctx_display=$((100 - ctx_used_int))
  fi
fi

# --- Costo de sesión en USD ---
# Nota: "cost.total_cost_usd" no figura en el esquema JSON documentado para
# este agente; si Claude Code no lo envía, este segmento simplemente se omite.
cost_display=""
cost_val="$(jget '.cost.total_cost_usd // empty')"
if [ -n "$cost_val" ]; then
  cost_display="$(printf '$%.2f' "$cost_val" 2>/dev/null)"
fi

# --- Rate limits de suscripción (ventanas 5h / 7d) ---
# Solo presentes para suscriptores de Claude.ai tras la primera respuesta de API.
rl5h_display=""
rl5h_val="$(jget '.rate_limits.five_hour.used_percentage // empty')"
if [ -n "$rl5h_val" ]; then
  rl5h_int="$(printf '%.0f' "$rl5h_val" 2>/dev/null)"
  [ -n "$rl5h_int" ] && rl5h_display="5h ${rl5h_int}%"
fi

rl7d_display=""
rl7d_val="$(jget '.rate_limits.seven_day.used_percentage // empty')"
if [ -n "$rl7d_val" ]; then
  rl7d_int="$(printf '%.0f' "$rl7d_val" 2>/dev/null)"
  [ -n "$rl7d_int" ] && rl7d_display="7d ${rl7d_int}%"
fi

# --- Ensamblar línea final ---
segment_dir="$dir_name"
[ -n "$branch" ] && segment_dir="$segment_dir ($branch)"

line="⏵ $model_name · $segment_dir"
[ -n "$ctx_display" ] && line="$line · ctx ${ctx_display}%"
[ -n "$cost_display" ] && line="$line · $cost_display"
[ -n "$rl5h_display" ] && line="$line · $rl5h_display"
[ -n "$rl7d_display" ] && line="$line · $rl7d_display"

printf '%s\n' "$line"
exit 0
