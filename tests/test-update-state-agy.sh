#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/helpers.sh"
HOOK="$DIR/../hooks/update-state-agy.sh"

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

# 1. repo limpio -> decision allow, exit 0
R="$(make_repo)"
OUT="$(cd "$R" && echo '{}' | bash "$HOOK" 2>/dev/null)"
assert_eq "0" "$?" "repo limpio: exit 0"
assert_eq "allow" "$(printf '%s' "$OUT" | jq -r '.decision')" \
  "repo limpio: decision allow"

# 2. cambios sin tocar PROJECT-STATE.md -> decision deny con reason, PERO exit 0
#    (contrato agy: exit != 0 se trata como fallo del hook, no como bloqueo)
echo "code" > "$R/main.py"
OUT="$(cd "$R" && echo '{}' | bash "$HOOK" 2>/dev/null)"
assert_eq "0" "$?" "deny también debe salir con exit 0"
assert_eq "deny" "$(printf '%s' "$OUT" | jq -r '.decision')" \
  "cambios sin estado: decision deny"
assert_contains "$(printf '%s' "$OUT" | jq -r '.reason')" "PROJECT-STATE.md" \
  "reason explica qué actualizar"

# 3. estado actualizado -> decision allow
echo "actualizado" >> "$R/PROJECT-STATE.md"
OUT="$(cd "$R" && echo '{}' | bash "$HOOK" 2>/dev/null)"
assert_eq "allow" "$(printf '%s' "$OUT" | jq -r '.decision')" \
  "estado actualizado: decision allow"

# 4. respeta el cwd del payload aunque el hook corra desde otro directorio
R2="$(make_repo)"
echo "code" > "$R2/main.py"
OUT="$(cd /tmp && printf '{"cwd": "%s"}' "$R2" | bash "$HOOK" 2>/dev/null)"
assert_eq "deny" "$(printf '%s' "$OUT" | jq -r '.decision')" \
  "usa el cwd del payload para evaluar el repo"

rm -rf "$R" "$R2"
report
