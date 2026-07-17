#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/helpers.sh"
INSTALL="$DIR/../install.sh"
HOOK_PATH="$(cd "$DIR/../hooks" && pwd)/update-state.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/mi-proyecto"

# 1. instala en un proyecto vacío (sin BMAD, que requiere red)
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/mi-proyecto" >/dev/null 2>&1
assert_eq "0" "$?" "install debe terminar bien"

# 2. crea PROJECT-STATE.md con el nombre del proyecto
assert_contains "$(cat "$TMP/mi-proyecto/PROJECT-STATE.md")" "mi-proyecto" \
  "PROJECT-STATE.md lleva el nombre del proyecto"

# 3. añade el snippet a CLAUDE.md, con el token <AGF_HOME> sustituido
assert_contains "$(cat "$TMP/mi-proyecto/CLAUDE.md")" "AGF:BEGIN" \
  "CLAUDE.md contiene el snippet"
assert_not_contains "$(cat "$TMP/mi-proyecto/CLAUDE.md")" "<AGF_HOME>" \
  "el token <AGF_HOME> fue sustituido por la ruta real"

# 4. registra el hook Stop en settings.json
assert_contains "$(cat "$TMP/mi-proyecto/.claude/settings.json")" "$HOOK_PATH" \
  "settings.json referencia update-state.sh"

# 5. idempotencia: segunda corrida no duplica nada
echo "contenido-previo" >> "$TMP/mi-proyecto/PROJECT-STATE.md"
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/mi-proyecto" >/dev/null 2>&1
assert_eq "1" "$(grep -c 'AGF:BEGIN' "$TMP/mi-proyecto/CLAUDE.md")" \
  "snippet no se duplica"
assert_eq "1" "$(grep -c "$HOOK_PATH" "$TMP/mi-proyecto/.claude/settings.json")" \
  "hook no se duplica"
assert_contains "$(cat "$TMP/mi-proyecto/PROJECT-STATE.md")" "contenido-previo" \
  "PROJECT-STATE.md existente no se sobrescribe"

# 6. respeta un settings.json preexistente (merge, no clobber)
mkdir -p "$TMP/otro/.claude"
echo '{"permissions":{"allow":["WebSearch"]}}' > "$TMP/otro/.claude/settings.json"
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/otro" >/dev/null 2>&1
OUT="$(cat "$TMP/otro/.claude/settings.json")"
assert_contains "$OUT" "WebSearch" "conserva configuración previa"
assert_contains "$OUT" "$HOOK_PATH" "añade el hook al settings existente"

report
