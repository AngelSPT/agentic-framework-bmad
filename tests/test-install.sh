#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/helpers.sh"
INSTALL="$DIR/../install.sh"
HOOK_PATH="$(cd "$DIR/../hooks" && pwd)/update-state.sh"
HOOK_AGY_PATH="$(cd "$DIR/../hooks" && pwd)/update-state-agy.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/mi-proyecto"
# AGF_BIN_DIR: que los tests no toquen el ~/.local/bin real
export AGF_BIN_DIR="$TMP/bin"

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

# 7. symlink de agf en AGF_BIN_DIR
assert_eq "$(cd "$DIR/../bin" && pwd)/agf" "$(readlink -f "$TMP/bin/agf")" \
  "crea symlink de agf en el bin dir"

# 8. runner antigravity: snippet en AGENTS.md, hook Stop en .agents/hooks.json
mkdir -p "$TMP/agy-proj"
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/agy-proj" --runner antigravity >/dev/null 2>&1
assert_eq "0" "$?" "install --runner antigravity debe terminar bien"
assert_contains "$(cat "$TMP/agy-proj/AGENTS.md")" "AGF:BEGIN" \
  "AGENTS.md contiene el snippet"
assert_not_contains "$(cat "$TMP/agy-proj/AGENTS.md")" "<AGF_HOME>" \
  "el token <AGF_HOME> fue sustituido también en AGENTS.md"
assert_eq "no" "$([[ -f "$TMP/agy-proj/CLAUDE.md" ]] && echo si || echo no)" \
  "runner antigravity no toca CLAUDE.md"
assert_contains "$(cat "$TMP/agy-proj/.agents/hooks.json")" "$HOOK_AGY_PATH" \
  "hooks.json referencia el adaptador update-state-agy.sh"
assert_contains "$(cat "$TMP/agy-proj/.agents/hooks.json")" '"Stop"' \
  "el hook se registra en el evento Stop"

# 9. idempotencia del runner antigravity
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/agy-proj" --runner antigravity >/dev/null 2>&1
assert_eq "1" "$(grep -c 'AGF:BEGIN' "$TMP/agy-proj/AGENTS.md")" \
  "snippet en AGENTS.md no se duplica"
assert_eq "1" "$(grep -c "$HOOK_AGY_PATH" "$TMP/agy-proj/.agents/hooks.json")" \
  "hook agy no se duplica"

# 10. runner desconocido -> exit != 0
mkdir -p "$TMP/malo"
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/malo" --runner cursor >/dev/null 2>&1
assert_eq "1" "$?" "runner desconocido debe fallar"

# 11. cambio de runner: reinstalar con el otro runner migra el bloque AGF
mkdir -p "$TMP/cambio"
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/cambio" >/dev/null 2>&1
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/cambio" --runner antigravity >/dev/null 2>&1
assert_eq "0" "$(grep -c 'AGF:BEGIN' "$TMP/cambio/CLAUDE.md")" \
  "claude→agy: quita el bloque AGF de CLAUDE.md"
assert_eq "1" "$(grep -c 'AGF:BEGIN' "$TMP/cambio/AGENTS.md")" \
  "claude→agy: pone el bloque AGF en AGENTS.md"
AGF_SKIP_BMAD=1 bash "$INSTALL" "$TMP/cambio" --runner claude >/dev/null 2>&1
assert_eq "0" "$(grep -c 'AGF:BEGIN' "$TMP/cambio/AGENTS.md")" \
  "agy→claude: quita el bloque AGF de AGENTS.md"
assert_eq "1" "$(grep -c 'AGF:BEGIN' "$TMP/cambio/CLAUDE.md")" \
  "agy→claude: pone el bloque AGF en CLAUDE.md"

report
