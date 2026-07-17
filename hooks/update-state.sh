#!/usr/bin/env bash
# Hook Stop de Claude Code: exige que PROJECT-STATE.md refleje el trabajo de
# la sesión. Si hay cambios en el repo pero el estado no se tocó, bloquea el
# cierre (exit 2) y pide actualizarlo. Corre con cwd = raíz del proyecto.
set -u

INPUT="$(cat)"

# Evitar bucle infinito: si ya venimos de un bloqueo de este hook, dejar salir.
if printf '%s' "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

STATE="PROJECT-STATE.md"

# Proyecto sin framework AGF o sin git: este hook no opina.
[[ -f "$STATE" ]] || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

CHANGES="$(git status --porcelain 2>/dev/null)"
[[ -z "$CHANGES" ]] && exit 0

if ! printf '%s' "$CHANGES" | grep -q "PROJECT-STATE.md"; then
  {
    echo "Hay cambios en el repo pero PROJECT-STATE.md no fue actualizado."
    echo "Antes de terminar: actualiza la tabla de Stories y la sección"
    echo "'Última sesión' (fecha, resumen, siguiente paso)."
  } >&2
  exit 2
fi

exit 0
