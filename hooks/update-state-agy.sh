#!/usr/bin/env bash
# Adaptador del hook Stop para Antigravity CLI (agy).
# Contrato agy, distinto al de Claude Code: el hook debe salir SIEMPRE con 0
# (exit != 0 se interpreta como fallo del hook, no como bloqueo) y el
# veredicto va en JSON por stdout:
#   {"decision":"allow"}  |  {"decision":"deny","reason":"..."}
# La lógica real vive en update-state.sh (su exit 2 = bloquear).
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT="$(cat)"

# agy no garantiza cwd = raíz del proyecto: usar el cwd del payload si viene.
CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)"
[[ -n "$CWD" && -d "$CWD" ]] && cd "$CWD"

MSG="$(printf '%s' "$INPUT" | bash "$DIR/update-state.sh" 2>&1)"
if [[ $? -eq 2 ]]; then
  jq -n --arg r "$MSG" '{decision: "deny", reason: $r}'
else
  echo '{"decision": "allow"}'
fi
exit 0
