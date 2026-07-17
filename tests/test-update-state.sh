#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/helpers.sh"
HOOK="$DIR/../hooks/update-state.sh"

make_repo() { # crea repo git temporal con PROJECT-STATE.md commiteado
  local tmp
  tmp="$(mktemp -d)"
  git -C "$tmp" init -q -b main
  git -C "$tmp" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  echo "# Estado" > "$tmp/PROJECT-STATE.md"
  git -C "$tmp" add PROJECT-STATE.md
  git -C "$tmp" -c user.email=t@t -c user.name=t commit -q -m state
  echo "$tmp"
}

# 1. sin PROJECT-STATE.md (proyecto sin framework) -> exit 0, no opina
TMP1="$(mktemp -d)"
( cd "$TMP1" && echo '{}' | bash "$HOOK" ) >/dev/null 2>&1
assert_eq "0" "$?" "sin PROJECT-STATE.md debe dejar salir"

# 2. repo limpio (sin cambios) -> exit 0
R="$(make_repo)"
( cd "$R" && echo '{}' | bash "$HOOK" ) >/dev/null 2>&1
assert_eq "0" "$?" "repo limpio debe dejar salir"

# 3. cambios en código SIN tocar PROJECT-STATE.md -> exit 2 (bloquea)
echo "code" > "$R/main.py"
( cd "$R" && echo '{}' | bash "$HOOK" ) >/dev/null 2>&1
assert_eq "2" "$?" "cambios sin actualizar estado deben bloquear"

# 4. cambios en código Y en PROJECT-STATE.md -> exit 0
echo "actualizado" >> "$R/PROJECT-STATE.md"
( cd "$R" && echo '{}' | bash "$HOOK" ) >/dev/null 2>&1
assert_eq "0" "$?" "estado actualizado debe dejar salir"

# 5. stop_hook_active=true -> exit 0 siempre (evita bucle)
R2="$(make_repo)"
echo "code" > "$R2/main.py"
( cd "$R2" && echo '{"stop_hook_active": true}' | bash "$HOOK" ) >/dev/null 2>&1
assert_eq "0" "$?" "stop_hook_active debe dejar salir"

rm -rf "$TMP1" "$R" "$R2"
report
