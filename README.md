# agentic-framework

Capa mínima de orquestación multi-proyecto para Claude Code sobre
[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) oficial.
Guía de uso diario: [`GUIA.md`](GUIA.md).
Diseño completo: `docs/superpowers/specs/2026-07-16-bmad-adaptation-design.md`.

## Qué resuelve

Trabajo paralelo **entre proyectos** con cuota Claude Pro: una sesión de
Claude Code por proyecto, memoria persistente en archivos
(`PROJECT-STATE.md`) y ciclo BMAD fire-and-forget con gates automáticos.

## Instalación en un proyecto

```bash
./install.sh ~/PROYECTOS/mi-proyecto                        # runner Claude Code
./install.sh ~/PROYECTOS/mi-proyecto --runner antigravity   # runner Antigravity CLI
```

Hace 5 cosas (idempotente): instala BMAD (módulo BMM, tool según runner),
copia `PROJECT-STATE.md`, añade las reglas AGF al archivo de contexto del
runner (`CLAUDE.md` o `AGENTS.md`), registra el hook Stop
(`.claude/settings.json` o `.agents/hooks.json`) y enlaza `agf` en
`~/.local/bin`. Requiere `jq` y `pnpm` (o `npx`).

Cada proyecto usa **un solo runner**, elegido al instalar; `agf start` lanza
`claude` o `agy` según dónde estén las reglas AGF. Para el runner antigravity
hace falta [Antigravity CLI](https://github.com/google-antigravity/antigravity-cli)
instalado y logueado (cuota Google, separada de la de Claude).

## Uso diario

```bash
agf start odoo-reylub gmspweb   # una ventana tmux por proyecto, corriendo claude
agf status                      # fase y feature de cada proyecto (cero tokens)
agf list                        # proyectos con el framework instalado
```

Regla de cuota Pro: **máximo 2 ciclos fire-and-forget simultáneos** por
plan (los ciclos en Antigravity consumen cuota Google, no cuentan contra
Claude Pro).

## Componentes

| Ruta | Qué hace |
|---|---|
| `bin/agf` | Launcher/monitor multi-proyecto (bash + tmux) |
| `templates/PROJECT-STATE.md` | Memoria del proyecto entre sesiones |
| `templates/CLAUDE-snippet.md` | Reglas del ciclo BMAD adaptado (frugalidad Pro) |
| `hooks/phase-gate.sh` | Bloquea fases sin artefacto previo (falla cerrado) |
| `hooks/update-state.sh` | Hook Stop: exige `PROJECT-STATE.md` al día |
| `hooks/update-state-agy.sh` | Adaptador del hook Stop al contrato de Antigravity |
| `install.sh` | Bootstrap idempotente de todo lo anterior |

## Tests

```bash
tests/run-tests.sh
```

## Estado actual

La implementación está completa y la suite pasa (36 tests), pero el framework
**aún no está validado end-to-end**: falta la comprobación de instalación
sobre un proyecto real y la prueba piloto del ciclo completo con sus 4
métricas. El detalle vive en [`PROJECT-STATE.md`](PROJECT-STATE.md) (Story 9)
y en la Task 9 del plan de implementación. No hacer rollout al resto de
proyectos antes de cerrar esa validación.
