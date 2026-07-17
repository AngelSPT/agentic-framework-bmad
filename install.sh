#!/usr/bin/env bash
# Bootstrap del framework AGF en un proyecto.
# Uso: install.sh <dir-proyecto> [--runner claude|antigravity]
# Idempotente: correrlo dos veces deja el proyecto igual que una.
#   AGF_SKIP_BMAD=1  salta la instalación de BMAD (tests / sin red)
#   AGF_BIN_DIR      destino del symlink de agf (default: ~/.local/bin)
set -euo pipefail

AGF_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUNNER="claude"
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --runner) RUNNER="${2:?--runner necesita valor}"; shift 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done
[[ -n "$TARGET" ]] || { echo "uso: install.sh <dir-proyecto> [--runner claude|antigravity]" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

case "$RUNNER" in
  claude)
    # Claude Code: reglas en CLAUDE.md, hook Stop en .claude/settings.json
    BMAD_TOOL="claude-code"
    RULES_FILE="CLAUDE.md"
    OTHER_RULES_FILE="AGENTS.md"
    ;;
  antigravity)
    # Antigravity CLI (agy): lee AGENTS.md y hooks en .agents/. El tool ID de
    # BMAD es "gemini" porque apunta a .agents/skills (lo que lee agy); el ID
    # "antigravity" apunta a .agent/ (convención del IDE, no del CLI).
    BMAD_TOOL="gemini"
    RULES_FILE="AGENTS.md"
    OTHER_RULES_FILE="CLAUDE.md"
    ;;
  *)
    echo "ERROR: runner desconocido '$RUNNER' (valores: claude, antigravity)" >&2
    exit 1
    ;;
esac

command -v jq >/dev/null 2>&1 || { echo "ERROR: se requiere jq" >&2; exit 1; }

# 1. BMAD-METHOD oficial (pnpm preferido sobre npm/npx)
#    Sobre una instalación BMAD existente el default es quick-update, que
#    conserva los tools previos e ignora --tools: forzar --action update para
#    que una conversión de runner añada el tool nuevo.
if [[ "${AGF_SKIP_BMAD:-0}" != "1" ]]; then
  BMAD_ACTION=()
  [[ -d "$TARGET/_bmad" ]] && BMAD_ACTION=(--action update)
  if command -v pnpm >/dev/null 2>&1; then
    pnpm dlx bmad-method install --directory "$TARGET" --modules bmm --tools "$BMAD_TOOL" "${BMAD_ACTION[@]}" --yes
  else
    npx bmad-method install --directory "$TARGET" --modules bmm --tools "$BMAD_TOOL" "${BMAD_ACTION[@]}" --yes
  fi
fi

# 2. PROJECT-STATE.md (no sobrescribir si ya existe)
if [[ ! -f "$TARGET/PROJECT-STATE.md" ]]; then
  sed "s/<NOMBRE>/$(basename "$TARGET")/" \
    "$AGF_HOME/templates/PROJECT-STATE.md" > "$TARGET/PROJECT-STATE.md"
  echo "creado: PROJECT-STATE.md"
fi

# 3. Snippet de reglas AGF (idempotente por marcador AGF:BEGIN)
#    CLAUDE.md para claude, AGENTS.md para antigravity; mismo contenido.
#    Sustituye el token <AGF_HOME> por la ruta real de este repo.
RULES_MD="$TARGET/$RULES_FILE"
if ! grep -q 'AGF:BEGIN' "$RULES_MD" 2>/dev/null; then
  { [[ -s "$RULES_MD" ]] && echo ""
    sed "s|<AGF_HOME>|$AGF_HOME|g" "$AGF_HOME/templates/CLAUDE-snippet.md"
  } >> "$RULES_MD"
  echo "actualizado: $RULES_FILE"
fi

# 3b. Cambio de runner: retirar el bloque AGF del archivo del otro runner
#     (agf start decide el runner por dónde está el bloque, con AGENTS.md
#     ganando; sin esta limpieza la conversión a claude no surtiría efecto).
OTHER_MD="$TARGET/$OTHER_RULES_FILE"
if grep -q 'AGF:BEGIN' "$OTHER_MD" 2>/dev/null; then
  sed -i '/<!-- AGF:BEGIN/,/<!-- AGF:END -->/d' "$OTHER_MD"
  echo "limpiado: bloque AGF retirado de $OTHER_RULES_FILE"
fi

# 4. Hook Stop, según el contrato de cada runner
if [[ "$RUNNER" == "claude" ]]; then
  # Claude Code: .claude/settings.json (merge con jq, sin duplicar)
  SETTINGS_DIR="$TARGET/.claude"
  SETTINGS="$SETTINGS_DIR/settings.json"
  HOOK_CMD="$AGF_HOME/hooks/update-state.sh"
  mkdir -p "$SETTINGS_DIR"
  [[ -s "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

  jq --arg cmd "$HOOK_CMD" '
    .hooks.Stop = (
      ((.hooks.Stop // [])
        | map(select(((.hooks // []) | map(.command) | index($cmd)) | not)))
      + [{"hooks": [{"type": "command", "command": $cmd}]}]
    )
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
else
  # Antigravity: .agents/hooks.json; la clave con nombre fijo hace el paso
  # idempotente (reasignarla no duplica). Ruta absoluta obligatoria.
  HOOKS_DIR="$TARGET/.agents"
  HOOKS_JSON="$HOOKS_DIR/hooks.json"
  HOOK_CMD="$AGF_HOME/hooks/update-state-agy.sh"
  mkdir -p "$HOOKS_DIR"
  [[ -s "$HOOKS_JSON" ]] || echo '{}' > "$HOOKS_JSON"

  jq --arg cmd "$HOOK_CMD" '
    ."agf-update-state" = {
      "Stop": [{"hooks": [{"type": "command", "command": $cmd, "timeout": 30}]}]
    }
  ' "$HOOKS_JSON" > "$HOOKS_JSON.tmp" && mv "$HOOKS_JSON.tmp" "$HOOKS_JSON"
fi

# 5. Symlink de agf para tenerlo en el PATH
BIN_DIR="${AGF_BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$BIN_DIR"
ln -sf "$AGF_HOME/bin/agf" "$BIN_DIR/agf"

echo "OK: framework AGF instalado en $TARGET (runner: $RUNNER)"
