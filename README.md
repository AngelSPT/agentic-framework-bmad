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
