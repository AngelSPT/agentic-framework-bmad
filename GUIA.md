# Guía de uso — agentic-framework (AGF)

Chuleta práctica para el día a día. El detalle de diseño está en
`docs/superpowers/specs/` y la referencia de componentes en el `README.md`.

## La idea en 3 líneas

Cada proyecto de `~/PROYECTOS` lleva su propio ciclo BMAD (PRD → arquitectura
→ stories → implementación → QA) de forma fire-and-forget: tú defines la
feature, el agente recorre el ciclo y tú revisas al final. `agf` te deja
lanzar y vigilar varios proyectos a la vez, cada uno en su ventana tmux.

## Conceptos clave

- **Runner**: la herramienta que ejecuta el ciclo en ese proyecto. O
  `claude` (Claude Code, cuota Claude Pro) o `agy` (Antigravity CLI, cuota
  Google). Un proyecto usa **un solo runner**; se elige al instalar y se
  puede cambiar reinstalando.
- **`PROJECT-STATE.md`**: la memoria del proyecto entre sesiones (feature
  activa, fase, tabla de stories, bloqueos). Es lo que lee `agf status` y lo
  que permite retomar cualquier proyecto en frío. Un hook impide cerrar
  sesión con trabajo hecho sin actualizarlo.
- **Gates de fase**: antes de cada fase se comprueba que exista el artefacto
  de la anterior (PRD → `docs/prd.md`, etc.). Sin artefacto, no se avanza.

## Iniciar un proyecto

```bash
# Proyecto nuevo desde cero
mkdir ~/PROYECTOS/mi-proyecto && git -C ~/PROYECTOS/mi-proyecto init

# Instalar el framework (nuevo o existente, da igual; es idempotente)
cd ~/PROYECTOS/agentic-framework
./install.sh ~/PROYECTOS/mi-proyecto                        # runner claude
./install.sh ~/PROYECTOS/mi-proyecto --runner antigravity   # runner agy
```

Esto instala BMAD, crea `PROJECT-STATE.md`, escribe las reglas AGF en el
archivo de contexto del runner (`CLAUDE.md` o `AGENTS.md`), registra el hook
Stop y enlaza `agf` en `~/.local/bin`. Después conviene commitear:

```bash
git -C ~/PROYECTOS/mi-proyecto add -A && git -C ~/PROYECTOS/mi-proyecto commit -m "chore: bootstrap AGF"
```

## Cambiar el runner de un proyecto

Reinstalar con el runner deseado — nada más:

```bash
./install.sh ~/PROYECTOS/mi-proyecto --runner claude       # agy → claude
./install.sh ~/PROYECTOS/mi-proyecto --runner antigravity  # claude → agy
```

La reinstalación mueve el bloque de reglas AGF al archivo correcto (quita el
del runner anterior), añade el tool BMAD que falte y registra el hook del
runner nuevo. Los restos del runner anterior (`.claude/settings.json` o
`.agents/hooks.json`) son inofensivos: solo actúan si abres esa herramienta.

## Comandos `agf`

| Comando | Qué hace |
|---|---|
| `agf start <proyecto...>` | Abre la sesión tmux `agf` con una ventana por proyecto, corriendo el runner de cada uno |
| `agf status` | Tabla proyecto / fase / feature de todo `~/PROYECTOS` — sin gastar tokens |
| `agf list` | Proyectos que tienen el framework instalado |

Variables útiles: `AGF_ROOT` (raíz de proyectos, default `~/PROYECTOS`),
`AGF_DRY_RUN=1` (imprime los comandos tmux sin ejecutarlos).

## Flujo de trabajo diario

```bash
agf status                      # 1. ¿cómo quedó todo ayer?
agf start odoo-reylub vps-setup # 2. abre los proyectos del día
```

3. En la ventana de cada proyecto, escribe la feature en una frase. El agente
   lee `PROJECT-STATE.md`, sigue las reglas AGF y recorre el ciclo solo.
4. Déjalo trabajar (fire-and-forget). Vuelve cuando quieras y revisa con
   `agf status` desde fuera, sin abrir la sesión.
5. Al final revisa el resultado y el `PROJECT-STATE.md` del proyecto: qué
   stories se completaron, qué supuestos tomó el PM, si hay bloqueos.

### Moverse en tmux (lo mínimo)

| Teclas | Acción |
|---|---|
| `Ctrl-b` + número | Ir a la ventana N (cada proyecto es una ventana) |
| `Ctrl-b` `n` / `p` | Ventana siguiente / anterior |
| `Ctrl-b` `d` | Salir dejando todo corriendo (detach) |
| `tmux attach -t agf` | Volver a entrar |

## Reglas de oro

1. **Máximo 2 ciclos fire-and-forget a la vez por plan** (los de agy gastan
   cuota Google, no cuentan contra Claude Pro).
2. **No edites el bloque `AGF:BEGIN…AGF:END`** de `CLAUDE.md`/`AGENTS.md`:
   lo gestiona `install.sh`. Tus reglas propias van fuera del bloque.
3. **`PROJECT-STATE.md` manda.** Si el agente terminó raro o cortaste la
   sesión, ese archivo dice exactamente dónde retomar.
4. Si QA rechaza la misma story 2 veces, el ciclo se detiene solo y lo anota
   en "Bloqueos" — revísalo tú antes de relanzar.

## Problemas frecuentes

- **`agf: command not found`** → corre cualquier `./install.sh <proyecto>`
  (crea el symlink) o `ln -sf ~/PROYECTOS/agentic-framework/bin/agf ~/.local/bin/agf`.
- **No me deja cerrar la sesión** ("PROJECT-STATE.md no fue actualizado") →
  es el hook Stop haciendo su trabajo: pide al agente actualizar la tabla de
  Stories y "Última sesión", o hazlo tú, y cierra de nuevo.
- **El agente quiere saltarse una fase** → el gate salió con "BLOQUEADO":
  falta el artefacto de la fase anterior (p. ej. `docs/prd.md`). Completa esa
  fase primero.
- **Cambié el runner y `agf start` lanza el antiguo** → reinstala con
  `--runner` (versiones viejas no limpiaban el bloque del otro archivo);
  `agf` decide mirando dónde está el bloque AGF, y `AGENTS.md` gana.
- **Tests del framework**: `tests/run-tests.sh` desde el repo.
