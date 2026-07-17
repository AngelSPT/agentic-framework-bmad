# Capa de Orquestación AGF — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir la capa mínima de orquestación multi-proyecto (`agf` CLI, plantillas de estado, hooks y `install.sh`) sobre BMAD-METHOD oficial, según el spec `docs/superpowers/specs/2026-07-16-bmad-adaptation-design.md`.

**Architecture:** Repo central `agentic-framework` con scripts bash sin dependencias (salvo `jq` para `install.sh` y `tmux` para `agf start`). Los proyectos consumen la capa por referencia absoluta (hooks) y por copia (plantillas). BMAD oficial se instala por proyecto vía `pnpm dlx`/`npx` y no se modifica.

**Tech Stack:** Bash puro, tmux, jq, BMAD-METHOD v6.x. Tests con un mini-harness bash propio (`tests/`), sin frameworks externos.

**Convenciones para el ejecutor:**
- Directorio de trabajo: `/home/angel/PROYECTOS/agentic-framework` (repo git ya inicializado, rama `main`).
- Todo commit termina con el trailer `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Todos los scripts llevan `chmod +x` en el paso donde se crean.

---

## Estructura de archivos final

```
agentic-framework/
├── bin/agf                      # CLI: start | status | list
├── templates/
│   ├── PROJECT-STATE.md         # plantilla de estado por proyecto
│   └── CLAUDE-snippet.md        # reglas AGF para el CLAUDE.md de cada repo
├── hooks/
│   ├── phase-gate.sh            # gate de fases BMAD (falla cerrado)
│   └── update-state.sh          # hook Stop: exige PROJECT-STATE.md actualizado
├── install.sh                   # bootstrap de un proyecto
├── tests/
│   ├── helpers.sh               # asserts del mini-harness
│   ├── run-tests.sh             # ejecuta todos los test-*.sh
│   ├── test-phase-gate.sh
│   ├── test-update-state.sh
│   ├── test-agf.sh
│   └── test-install.sh
└── docs/superpowers/...         # specs y planes (ya existe)
```

---

### Task 1: Mini-harness de tests

**Files:**
- Create: `tests/helpers.sh`
- Create: `tests/run-tests.sh`

- [ ] **Step 1: Crear `tests/helpers.sh`**

```bash
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
```

- [ ] **Step 2: Crear `tests/run-tests.sh`**

```bash
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
```

- [ ] **Step 3: Dar permisos y verificar que corre en vacío**

Run: `chmod +x tests/run-tests.sh && tests/run-tests.sh`
Expected: imprime `TODOS LOS TESTS PASAN` y exit 0 (aún no hay test-*.sh).

- [ ] **Step 4: Commit**

```bash
git add tests/
git commit -m "feat: mini-harness de tests bash"
```

---

### Task 2: Plantilla PROJECT-STATE.md

**Files:**
- Create: `templates/PROJECT-STATE.md`

- [ ] **Step 1: Crear `templates/PROJECT-STATE.md`**

El formato de las líneas `**Fase:**` y `**Feature activa:**` es contrato: `agf status` (Task 4) las parsea con `sed`. No cambiar su formato sin cambiar el parser.

```markdown
# Estado del proyecto — <NOMBRE>

**Feature activa:** (ninguna)
**Fase:** idea

<!-- Fases válidas: idea | prd | arquitectura | stories | implementacion | qa | completado -->
<!-- Este archivo es la memoria del proyecto entre sesiones de Claude Code.  -->
<!-- Se actualiza tras completar cada story, ANTES de empezar la siguiente. -->

## Stories

| # | Story | Estado | Notas |
|---|-------|--------|-------|

<!-- Estados: pendiente | en-progreso | completada | bloqueada -->

## Supuestos tomados por las personas

(ninguno)

## Bloqueos

(ninguno)

<!-- Formato de bloqueo: story, motivo del rechazo de QA, qué intentó Dev -->

## Métricas del ciclo

- Ciclos completados sin intervención: 0
- Stories rechazadas por QA: 0
- Notas de consumo de cuota: —

## Última sesión

- Fecha: —
- Resumen: —
- Siguiente paso: —
```

- [ ] **Step 2: Verificar el contrato de parseo**

Run: `grep -c '^\*\*Fase:\*\* ' templates/PROJECT-STATE.md && grep -c '^\*\*Feature activa:\*\* ' templates/PROJECT-STATE.md`
Expected: `1` y `1`.

- [ ] **Step 3: Commit**

```bash
git add templates/PROJECT-STATE.md
git commit -m "feat: plantilla PROJECT-STATE.md (memoria entre sesiones)"
```

---

### Task 3: Plantilla CLAUDE-snippet.md (reglas AGF)

**Files:**
- Create: `templates/CLAUDE-snippet.md`

- [ ] **Step 1: Crear `templates/CLAUDE-snippet.md`**

Los marcadores `AGF:BEGIN`/`AGF:END` son contrato: `install.sh` (Task 6) los usa para idempotencia.

```markdown
<!-- AGF:BEGIN — no editar dentro de este bloque; lo gestiona agentic-framework -->
# Reglas del framework AGF (ciclo BMAD adaptado)

## Estado persistente
- Al INICIO de cada sesión: lee `PROJECT-STATE.md` antes de cualquier otra cosa.
- Tras completar cada story: actualiza `PROJECT-STATE.md` (tabla de Stories y
  "Última sesión") ANTES de empezar la siguiente story.
- Las fases válidas y el formato del archivo están definidos en la propia plantilla.

## Ciclo BMAD fire-and-forget
- Las personas BMAD (PM, Architect, Dev, QA) corren SIEMPRE como subagentes,
  cada una en su contexto aislado. Prohibido "Party Mode" (multi-persona en la
  sesión principal): consume demasiada cuota.
- Antes de iniciar una fase, ejecuta el gate:
  `bash <AGF_HOME>/hooks/phase-gate.sh <fase>` (fases: prd, arquitectura,
  stories, implementacion). Si sale con código 2, NO avances: completa la fase
  que falta. Nota para el ejecutor del plan: `<AGF_HOME>` es un token que
  `install.sh` (Task 7) sustituye por la ruta real del repo al copiar este
  snippet; `<NOMBRE>` en PROJECT-STATE.md funciona igual.
- Si una descripción de feature es ambigua, el PM anota sus supuestos en la
  sección "Supuestos" del PRD y en `PROJECT-STATE.md`, y CONTINÚA (no bloquea).
- QA valida cada story contra el PRD **y** el doc de arquitectura, no solo que
  funcione.
- Si QA rechaza la misma story 2 veces: DETÉN el ciclo, registra en
  `PROJECT-STATE.md` → "Bloqueos" (story, motivo, qué se intentó) y termina la
  sesión. No reintentar a ciegas.

## Frugalidad (cuota Claude Pro)
- Modelo por defecto para personas del ciclo: Sonnet.
- Artefactos acotados: PRD ≤ ~2 páginas; arquitectura ≤ ~2 páginas; una story
  = una unidad implementable en una sesión corta.
- Máximo 2 ciclos fire-and-forget simultáneos en toda la máquina (regla del
  usuario, no de este repo).
<!-- AGF:END -->
```

- [ ] **Step 2: Verificar marcadores**

Run: `grep -c 'AGF:BEGIN' templates/CLAUDE-snippet.md && grep -c 'AGF:END' templates/CLAUDE-snippet.md`
Expected: `1` y `1`.

- [ ] **Step 3: Commit**

```bash
git add templates/CLAUDE-snippet.md
git commit -m "feat: snippet de reglas AGF para CLAUDE.md de proyectos"
```

---

### Task 4: Hook phase-gate.sh

**Files:**
- Create: `hooks/phase-gate.sh`
- Test: `tests/test-phase-gate.sh`

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test-phase-gate.sh`:

```bash
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
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `bash tests/test-phase-gate.sh`
Expected: FAIL en varios asserts (el script `hooks/phase-gate.sh` no existe; los `bash` devuelven 127/126, no 0/2).

- [ ] **Step 3: Implementar `hooks/phase-gate.sh`**

```bash
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
```

Run: `chmod +x hooks/phase-gate.sh`

- [ ] **Step 4: Ejecutar el test y verificar que pasa**

Run: `bash tests/test-phase-gate.sh`
Expected: `tests: 8, fallos: 0` y exit 0.

- [ ] **Step 5: Commit**

```bash
git add hooks/phase-gate.sh tests/test-phase-gate.sh
git commit -m "feat: phase-gate.sh — gate de fases BMAD que falla cerrado"
```

---

### Task 5: Hook update-state.sh (Stop hook)

**Files:**
- Create: `hooks/update-state.sh`
- Test: `tests/test-update-state.sh`

Contexto para el ejecutor: los hooks `Stop` de Claude Code reciben JSON por stdin y corren con cwd = directorio del proyecto. Exit 2 bloquea el cierre de la sesión y devuelve el stderr a Claude como feedback. El campo `stop_hook_active: true` en el JSON indica que ya estamos en un ciclo de re-entrada del hook: hay que dejar salir para no crear un bucle infinito.

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test-update-state.sh`:

```bash
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
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `bash tests/test-update-state.sh`
Expected: FAIL en los asserts 3 y 5 como mínimo (el hook no existe; `bash` devuelve 127).

- [ ] **Step 3: Implementar `hooks/update-state.sh`**

```bash
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
```

Run: `chmod +x hooks/update-state.sh`

- [ ] **Step 4: Ejecutar el test y verificar que pasa**

Run: `bash tests/test-update-state.sh`
Expected: `tests: 5, fallos: 0` y exit 0.

- [ ] **Step 5: Commit**

```bash
git add hooks/update-state.sh tests/test-update-state.sh
git commit -m "feat: update-state.sh — hook Stop que exige estado al día"
```

---

### Task 6: CLI bin/agf (status, list, start)

**Files:**
- Create: `bin/agf`
- Test: `tests/test-agf.sh`

Decisiones que el código implementa: `AGF_ROOT` (default `$HOME/PROYECTOS`) localiza los proyectos; `AGF_DRY_RUN=1` imprime los comandos tmux en vez de ejecutarlos (para tests y depuración); `agf start` con más de 2 proyectos abre las ventanas pero avisa de la regla de cuota (el límite de 2 aplica a *ciclos disparados*, no a ventanas abiertas).

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test-agf.sh`:

```bash
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
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `bash tests/test-agf.sh`
Expected: FAIL en todos los asserts (`bin/agf` no existe).

- [ ] **Step 3: Implementar `bin/agf`**

```bash
#!/usr/bin/env bash
# agf — launcher y monitor multi-proyecto para Claude Code + BMAD.
#
# Comandos:
#   agf start <proyecto...>  abre una ventana tmux por proyecto corriendo claude
#   agf status               fase y feature de cada proyecto (lee PROJECT-STATE.md)
#   agf list                 proyectos con el framework instalado
#
# Config por entorno:
#   AGF_ROOT     raíz de proyectos (default: $HOME/PROYECTOS)
#   AGF_DRY_RUN  =1 imprime los comandos tmux en vez de ejecutarlos
set -u

AGF_ROOT="${AGF_ROOT:-$HOME/PROYECTOS}"
SESSION="agf"
DRY="${AGF_DRY_RUN:-0}"

usage() {
  sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

tmux_run() {
  if [[ "$DRY" == "1" ]]; then
    echo "tmux $*"
  else
    command tmux "$@"
  fi
}

session_exists() {
  [[ "$DRY" == "1" ]] && return 1
  command tmux has-session -t "$SESSION" 2>/dev/null
}

cmd_start() {
  [[ $# -ge 1 ]] || { echo "uso: agf start <proyecto...>" >&2; return 1; }

  if [[ $# -gt 2 ]]; then
    echo "AVISO: regla de cuota Pro — máximo 2 ciclos fire-and-forget" >&2
    echo "simultáneos. Se abren $# ventanas; no dispares más de 2 ciclos." >&2
  fi

  local p dir
  for p in "$@"; do
    dir="$AGF_ROOT/$p"
    [[ -d "$dir" ]] || { echo "ERROR: no existe $dir" >&2; return 1; }
  done

  if ! session_exists; then
    tmux_run new-session -d -s "$SESSION" -n "$1" -c "$AGF_ROOT/$1" claude
    shift
  fi
  for p in "$@"; do
    tmux_run new-window -t "$SESSION" -n "$p" -c "$AGF_ROOT/$p" claude
  done

  [[ "$DRY" == "1" ]] || tmux_run attach -t "$SESSION"
}

cmd_status() {
  local f proj fase feat found=0
  printf "%-32s %-16s %s\n" "PROYECTO" "FASE" "FEATURE"
  for f in "$AGF_ROOT"/*/PROJECT-STATE.md; do
    [[ -f "$f" ]] || continue
    found=1
    proj="$(basename "$(dirname "$f")")"
    fase="$(sed -n 's/^\*\*Fase:\*\* //p' "$f" | head -1)"
    feat="$(sed -n 's/^\*\*Feature activa:\*\* //p' "$f" | head -1)"
    printf "%-32s %-16s %s\n" "$proj" "${fase:-?}" "${feat:-?}"
  done
  [[ $found -eq 1 ]] || echo "(ningún proyecto con PROJECT-STATE.md en $AGF_ROOT)"
}

cmd_list() {
  local f found=0
  for f in "$AGF_ROOT"/*/PROJECT-STATE.md; do
    [[ -f "$f" ]] || continue
    found=1
    basename "$(dirname "$f")"
  done
  [[ $found -eq 1 ]] || echo "(ninguno)"
}

case "${1:-}" in
  start)  shift; cmd_start "$@" ;;
  status) cmd_status ;;
  list)   cmd_list ;;
  *)      usage; exit 1 ;;
esac
```

Run: `chmod +x bin/agf`

- [ ] **Step 4: Ejecutar el test y verificar que pasa**

Run: `bash tests/test-agf.sh`
Expected: `tests: 13, fallos: 0` y exit 0.

- [ ] **Step 5: Commit**

```bash
git add bin/agf tests/test-agf.sh
git commit -m "feat: CLI agf — start/status/list multi-proyecto sobre tmux"
```

---

### Task 7: install.sh (bootstrap de un proyecto)

**Files:**
- Create: `install.sh`
- Test: `tests/test-install.sh`

Responsabilidades: (1) instalar BMAD oficial (`pnpm dlx` con fallback a `npx`; se salta con `AGF_SKIP_BMAD=1`, usado por los tests), (2) copiar `PROJECT-STATE.md` si no existe, (3) añadir el snippet a `CLAUDE.md` una sola vez (marcador `AGF:BEGIN`), (4) registrar el hook Stop en `.claude/settings.json` con `jq`, sin duplicarlo. Debe ser idempotente: correrlo dos veces deja el proyecto igual que una.

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test-install.sh`:

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/helpers.sh"
INSTALL="$DIR/../install.sh"
HOOK_PATH="$(cd "$DIR/../hooks" && pwd)/update-state.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/mi-proyecto"

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

report
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `bash tests/test-install.sh`
Expected: FAIL en todos los asserts (`install.sh` no existe).

- [ ] **Step 3: Implementar `install.sh`**

```bash
#!/usr/bin/env bash
# Bootstrap del framework AGF en un proyecto.
# Uso: install.sh <dir-proyecto>
# Idempotente: correrlo dos veces deja el proyecto igual que una.
#   AGF_SKIP_BMAD=1  salta la instalación de BMAD (tests / sin red)
set -euo pipefail

AGF_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:?uso: install.sh <dir-proyecto>}"
TARGET="$(cd "$TARGET" && pwd)"

command -v jq >/dev/null 2>&1 || { echo "ERROR: se requiere jq" >&2; exit 1; }

# 1. BMAD-METHOD oficial (pnpm preferido sobre npm/npx)
if [[ "${AGF_SKIP_BMAD:-0}" != "1" ]]; then
  if command -v pnpm >/dev/null 2>&1; then
    pnpm dlx bmad-method install --directory "$TARGET" --modules bmm --tools claude-code --yes
  else
    npx bmad-method install --directory "$TARGET" --modules bmm --tools claude-code --yes
  fi
fi

# 2. PROJECT-STATE.md (no sobrescribir si ya existe)
if [[ ! -f "$TARGET/PROJECT-STATE.md" ]]; then
  sed "s/<NOMBRE>/$(basename "$TARGET")/" \
    "$AGF_HOME/templates/PROJECT-STATE.md" > "$TARGET/PROJECT-STATE.md"
  echo "creado: PROJECT-STATE.md"
fi

# 3. Snippet en CLAUDE.md (idempotente por marcador AGF:BEGIN)
#    Sustituye el token <AGF_HOME> por la ruta real de este repo.
CLAUDE_MD="$TARGET/CLAUDE.md"
if ! grep -q 'AGF:BEGIN' "$CLAUDE_MD" 2>/dev/null; then
  { [[ -s "$CLAUDE_MD" ]] && echo ""
    sed "s|<AGF_HOME>|$AGF_HOME|g" "$AGF_HOME/templates/CLAUDE-snippet.md"
  } >> "$CLAUDE_MD"
  echo "actualizado: CLAUDE.md"
fi

# 4. Hook Stop en .claude/settings.json (merge con jq, sin duplicar)
SETTINGS_DIR="$TARGET/.claude"
SETTINGS="$SETTINGS_DIR/settings.json"
HOOK_CMD="$AGF_HOME/hooks/update-state.sh"
mkdir -p "$SETTINGS_DIR"
[[ -s "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

jq --arg cmd "$HOOK_CMD" '
  .hooks.Stop = (
    ((.hooks.Stop // [])
      | map(select(((.hooks // []) | map(.command) | index($cmd)) | not)))
    + [{"hooks": [{"type": "command", "command": $cmd}]}]
  )
' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"

echo "OK: framework AGF instalado en $TARGET"
```

Run: `chmod +x install.sh`

- [ ] **Step 4: Ejecutar el test y verificar que pasa**

Run: `bash tests/test-install.sh`
Expected: `tests: 10, fallos: 0` y exit 0.

- [ ] **Step 5: Correr la suite completa**

Run: `tests/run-tests.sh`
Expected: los 4 archivos de test pasan; `TODOS LOS TESTS PASAN`; exit 0.

- [ ] **Step 6: Commit**

```bash
git add install.sh tests/test-install.sh
git commit -m "feat: install.sh — bootstrap idempotente de BMAD + capa AGF"
```

---

### Task 8: README del repo

**Files:**
- Create: `README.md`

- [ ] **Step 1: Crear `README.md`**

```markdown
# agentic-framework

Capa mínima de orquestación multi-proyecto para Claude Code sobre
[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) oficial.
Diseño completo: `docs/superpowers/specs/2026-07-16-bmad-adaptation-design.md`.

## Qué resuelve

Trabajo paralelo **entre proyectos** con cuota Claude Pro: una sesión de
Claude Code por proyecto, memoria persistente en archivos
(`PROJECT-STATE.md`) y ciclo BMAD fire-and-forget con gates automáticos.

## Instalación en un proyecto

```bash
./install.sh ~/PROYECTOS/mi-proyecto
```

Hace 4 cosas (idempotente): instala BMAD (módulo BMM, tool claude-code),
copia `PROJECT-STATE.md`, añade las reglas AGF al `CLAUDE.md` del proyecto y
registra el hook Stop en `.claude/settings.json`. Requiere `jq` y
`pnpm` (o `npx`).

## Uso diario

```bash
agf start odoo-reylub gmspweb   # una ventana tmux por proyecto, corriendo claude
agf status                      # fase y feature de cada proyecto (cero tokens)
agf list                        # proyectos con el framework instalado
```

Regla de cuota Pro: **máximo 2 ciclos fire-and-forget simultáneos.**

Para usar `agf` desde cualquier lugar:

```bash
ln -s "$(pwd)/bin/agf" ~/.local/bin/agf
```

## Componentes

| Ruta | Qué hace |
|---|---|
| `bin/agf` | Launcher/monitor multi-proyecto (bash + tmux) |
| `templates/PROJECT-STATE.md` | Memoria del proyecto entre sesiones |
| `templates/CLAUDE-snippet.md` | Reglas del ciclo BMAD adaptado (frugalidad Pro) |
| `hooks/phase-gate.sh` | Bloquea fases sin artefacto previo (falla cerrado) |
| `hooks/update-state.sh` | Hook Stop: exige `PROJECT-STATE.md` al día |
| `install.sh` | Bootstrap idempotente de todo lo anterior |

## Tests

```bash
tests/run-tests.sh
```
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: README con instalación, uso diario y componentes"
```

---

### Task 9: Piloto 1 — validación en proyecto de bajo riesgo (manual)

**Files:**
- Modify: `~/PROYECTOS/pruebas/` (o `social-media-content-generator/`, a elección del usuario)

Esta tarea valida el framework end-to-end según el plan de validación del spec. Requiere red (instala BMAD) y participación del usuario para elegir la feature piloto.

- [ ] **Step 1: Instalar en el proyecto piloto**

Run: `./install.sh ~/PROYECTOS/pruebas`
Expected: instalador de BMAD termina sin error; `OK: framework AGF instalado`; existen `PROJECT-STATE.md`, snippet en `CLAUDE.md` y hook en `.claude/settings.json`.

- [ ] **Step 2: Verificar visibilidad en agf**

Run: `AGF_ROOT=~/PROYECTOS bin/agf status`
Expected: `pruebas` aparece con fase `idea`.

- [ ] **Step 3: Correr una feature real pequeña por el ciclo completo**

El usuario define una feature de una frase en la sesión del piloto y dispara el ciclo fire-and-forget. Registrar en el `PROJECT-STATE.md` del piloto las 4 métricas del spec:
1. ¿El ciclo terminó sin intervención humana?
2. Cuota consumida por la feature (estimación subjetiva: ¿quedó cuota para un segundo ciclo ese día?).
3. ¿El código respetó el doc de arquitectura? (revisión del usuario)
4. ¿Retomar la sesión al día siguiente costó < 2 minutos?

- [ ] **Step 4: Registrar resultado y decidir**

Si las 4 métricas son aceptables → proceder al Piloto 2 (`odoo-reylub`, mismos pasos 1-3) y después al rollout con `install.sh` al resto de PROYECTOS. Si no → abrir issue/nota en `PROJECT-STATE.md` de este repo con lo que falló y ajustar antes de continuar.

- [ ] **Step 5: Commit de cierre**

```bash
git add -A
git commit -m "docs: resultados del piloto 1 y decisión de rollout"
```
