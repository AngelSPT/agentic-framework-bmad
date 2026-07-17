#!/usr/bin/env bash
# Gate de fases del ciclo BMAD. Falla CERRADO: ante duda, bloquea.
# Uso: phase-gate.sh <fase> [dir-proyecto]
#   fases: prd | arquitectura | stories | implementacion
#   exit 0 = fase desbloqueada; exit 2 = bloqueada (falta artefacto previo)
# Rutas de artefactos sobreescribibles vía AGF_PRD, AGF_ARCH, AGF_STORIES.
set -u

FASE="${1:-}"
DIR="${2:-$PWD}"
PRD="${AGF_PRD:-$DIR/docs/prd.md}"
ARCH="${AGF_ARCH:-$DIR/docs/architecture.md}"
STORIES="${AGF_STORIES:-$DIR/docs/stories}"

blocked() {
  echo "BLOQUEADO: $1" >&2
  exit 2
}

need_file() { # $1=ruta $2=nombre-fase-previa
  [[ -s "$1" ]] || blocked "falta artefacto '$1' — completa la fase '$2' primero"
}

case "$FASE" in
  prd)
    ;; # primera fase, sin prerrequisitos
  arquitectura)
    need_file "$PRD" "prd"
    ;;
  stories)
    need_file "$PRD" "prd"
    need_file "$ARCH" "arquitectura"
    ;;
  implementacion)
    need_file "$PRD" "prd"
    need_file "$ARCH" "arquitectura"
    [[ -d "$STORIES" && -n "$(ls -A "$STORIES" 2>/dev/null)" ]] \
      || blocked "no hay stories en '$STORIES' — completa la fase 'stories' primero"
    ;;
  *)
    blocked "fase desconocida o vacía: '$FASE'"
    ;;
esac

echo "OK: fase '$FASE' desbloqueada"
