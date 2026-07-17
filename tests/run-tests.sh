#!/usr/bin/env bash
# Ejecuta todos los tests/test-*.sh y falla si alguno falla.
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0
shopt -s nullglob
for t in "$DIR"/test-*.sh; do
  echo "== $(basename "$t")"
  bash "$t" || fail=1
done
shopt -u nullglob
if [[ $fail -eq 0 ]]; then echo "TODOS LOS TESTS PASAN"; else echo "HAY TESTS FALLANDO"; fi
exit $fail
