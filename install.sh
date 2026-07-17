#!/usr/bin/env bash
# Bootstrap del framework AGF en un proyecto.
# Uso: install.sh <dir-proyecto>
# Idempotente: correrlo dos veces deja el proyecto igual que una.
#   AGF_SKIP_BMAD=1  salta la instalación de BMAD (tests / sin red)
set -euo pipefail

AGF_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:?uso: install.sh <dir-proyecto>}"
TARGET="$(cd "$TARGET" && pwd)"

command -v jq >/dev/null 2>&1 || { echo "ERROR: se requiere jq" >&2; exit 1; }

# 1. BMAD-METHOD oficial (pnpm preferido sobre npm/npx)
if [[ "${AGF_SKIP_BMAD:-0}" != "1" ]]; then
  if command -v pnpm >/dev/null 2>&1; then
    pnpm dlx bmad-method install --directory "$TARGET" --modules bmm --tools claude-code --yes
  else
    npx bmad-method install --directory "$TARGET" --modules bmm --tools claude-code --yes
  fi
fi

# 2. PROJECT-STATE.md (no sobrescribir si ya existe)
if [[ ! -f "$TARGET/PROJECT-STATE.md" ]]; then
  sed "s/<NOMBRE>/$(basename "$TARGET")/" \
    "$AGF_HOME/templates/PROJECT-STATE.md" > "$TARGET/PROJECT-STATE.md"
  echo "creado: PROJECT-STATE.md"
fi

# 3. Snippet en CLAUDE.md (idempotente por marcador AGF:BEGIN)
#    Sustituye el token <AGF_HOME> por la ruta real de este repo.
CLAUDE_MD="$TARGET/CLAUDE.md"
if ! grep -q 'AGF:BEGIN' "$CLAUDE_MD" 2>/dev/null; then
  { [[ -s "$CLAUDE_MD" ]] && echo ""
    sed "s|<AGF_HOME>|$AGF_HOME|g" "$AGF_HOME/templates/CLAUDE-snippet.md"
  } >> "$CLAUDE_MD"
  echo "actualizado: CLAUDE.md"
fi

# 4. Hook Stop en .claude/settings.json (merge con jq, sin duplicar)
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

echo "OK: framework AGF instalado en $TARGET"
