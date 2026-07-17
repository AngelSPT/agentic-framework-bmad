#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/helpers.sh"
GATE="$DIR/../hooks/phase-gate.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1. fase prd: sin prerrequisitos -> exit 0
bash "$GATE" prd "$TMP" >/dev/null 2>&1
assert_eq "0" "$?" "prd no tiene prerrequisitos"

# 2. arquitectura sin PRD -> exit 2 (bloqueado)
bash "$GATE" arquitectura "$TMP" >/dev/null 2>&1
assert_eq "2" "$?" "arquitectura sin PRD debe bloquear"

# 3. arquitectura con PRD vacío -> exit 2 (falla cerrado)
mkdir -p "$TMP/docs" && touch "$TMP/docs/prd.md"
bash "$GATE" arquitectura "$TMP" >/dev/null 2>&1
assert_eq "2" "$?" "PRD vacío debe bloquear"

# 4. arquitectura con PRD real -> exit 0
echo "# PRD" > "$TMP/docs/prd.md"
bash "$GATE" arquitectura "$TMP" >/dev/null 2>&1
assert_eq "0" "$?" "arquitectura con PRD debe pasar"

# 5. implementacion sin stories -> exit 2
echo "# Arch" > "$TMP/docs/architecture.md"
bash "$GATE" implementacion "$TMP" >/dev/null 2>&1
assert_eq "2" "$?" "implementacion sin stories debe bloquear"

# 6. implementacion con stories -> exit 0
mkdir -p "$TMP/docs/stories" && echo "story" > "$TMP/docs/stories/s1.md"
bash "$GATE" implementacion "$TMP" >/dev/null 2>&1
assert_eq "0" "$?" "implementacion con stories debe pasar"

# 7. fase desconocida -> exit 2 (falla cerrado)
bash "$GATE" cualquier-cosa "$TMP" >/dev/null 2>&1
assert_eq "2" "$?" "fase desconocida debe bloquear"

# 8. sin argumento -> exit 2
bash "$GATE" "" "$TMP" >/dev/null 2>&1
assert_eq "2" "$?" "sin fase debe bloquear"

report
