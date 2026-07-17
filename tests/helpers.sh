#!/usr/bin/env bash
# Mini-harness de tests para bash. Uso: source helpers.sh; assert_*; report
TESTS_RUN=0
TESTS_FAILED=0

assert_eq() { # $1=esperado $2=obtenido $3=mensaje
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$1" != "$2" ]]; then
    echo "  FAIL: ${3:-assert_eq} (esperado '$1', obtuvo '$2')"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_contains() { # $1=texto $2=subcadena $3=mensaje
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$1" != *"$2"* ]]; then
    echo "  FAIL: ${3:-assert_contains} ('$2' no aparece en la salida)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_not_contains() { # $1=texto $2=subcadena $3=mensaje
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$1" == *"$2"* ]]; then
    echo "  FAIL: ${3:-assert_not_contains} ('$2' no debería aparecer)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

report() {
  echo "  tests: $TESTS_RUN, fallos: $TESTS_FAILED"
  [[ $TESTS_FAILED -eq 0 ]]
}
