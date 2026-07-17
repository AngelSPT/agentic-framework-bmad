#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/helpers.sh"
AGF="$DIR/../bin/agf"

# Fixture: AGF_ROOT con 3 proyectos, 2 con PROJECT-STATE.md
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/proj-a" "$ROOT/proj-b" "$ROOT/proj-c"
cat > "$ROOT/proj-a/PROJECT-STATE.md" <<'EOF'
# Estado del proyecto — proj-a
**Feature activa:** login-sso
**Fase:** implementacion
EOF
cat > "$ROOT/proj-b/PROJECT-STATE.md" <<'EOF'
# Estado del proyecto — proj-b
**Feature activa:** (ninguna)
**Fase:** idea
EOF

# 1. status lista solo proyectos con PROJECT-STATE.md, con fase y feature
OUT="$(AGF_ROOT="$ROOT" bash "$AGF" status)"
assert_contains "$OUT" "proj-a" "status incluye proj-a"
assert_contains "$OUT" "implementacion" "status muestra la fase"
assert_contains "$OUT" "login-sso" "status muestra la feature"
assert_contains "$OUT" "proj-b" "status incluye proj-b"
assert_not_contains "$OUT" "proj-c" "status excluye proyectos sin estado"

# 2. list muestra proyectos con framework instalado
OUT="$(AGF_ROOT="$ROOT" bash "$AGF" list)"
assert_contains "$OUT" "proj-a" "list incluye proj-a"
assert_not_contains "$OUT" "proj-c" "list excluye proj-c"

# 3. start en dry-run: new-session para el 1º, new-window para el resto
OUT="$(AGF_ROOT="$ROOT" AGF_DRY_RUN=1 bash "$AGF" start proj-a proj-b 2>/dev/null)"
assert_contains "$OUT" "new-session" "start crea la sesión tmux"
assert_contains "$OUT" "new-window" "start crea ventana para el 2º proyecto"
assert_contains "$OUT" "proj-b" "la ventana usa el nombre del proyecto"

# 4. start con proyecto inexistente -> exit 1
AGF_ROOT="$ROOT" AGF_DRY_RUN=1 bash "$AGF" start no-existe >/dev/null 2>&1
assert_eq "1" "$?" "proyecto inexistente debe fallar"

# 5. start con >2 proyectos -> aviso de regla de cuota en stderr
ERR="$(AGF_ROOT="$ROOT" AGF_DRY_RUN=1 bash "$AGF" start proj-a proj-b proj-c 2>&1 >/dev/null)"
assert_contains "$ERR" "2 ciclos" "avisa la regla de máximo 2 ciclos"

# 6. sin argumentos -> usage y exit 1
bash "$AGF" >/dev/null 2>&1
assert_eq "1" "$?" "sin comando debe mostrar uso y fallar"

report
