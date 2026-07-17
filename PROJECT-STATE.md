# Estado del proyecto — agentic-framework

**Feature activa:** capa-orquestacion-agf
**Fase:** qa

<!-- Fases válidas: idea | prd | arquitectura | stories | implementacion | qa | completado -->
<!-- Este archivo es la memoria del proyecto entre sesiones de Claude Code.  -->
<!-- Se actualiza tras completar cada story, ANTES de empezar la siguiente. -->

## Stories

| # | Story | Estado | Notas |
|---|-------|--------|-------|
| 1 | Mini-harness de tests bash | completada | commit bcd660d |
| 2 | Plantilla PROJECT-STATE.md | completada | commit 26de462 |
| 3 | Plantilla CLAUDE-snippet.md | completada | commit 7c1e018 |
| 4 | Hook phase-gate.sh | completada | commit d3546fb, 8 tests |
| 5 | Hook update-state.sh (Stop) | completada | commit a02d072, 5 tests |
| 6 | CLI bin/agf | completada | commit 9e2d3e6, 13 tests |
| 7 | install.sh idempotente | completada | commit 2b4368b, 10 tests |
| 8 | README | completada | commit 38c366f |
| 9a | Comprobación de instalación (sandbox, BMAD real) | completada | 2026-07-17, ver "Última sesión" |
| 9b | Piloto 1: ciclo completo en proyecto real | completada | 2026-07-17, vps-setup (greenfield) — funcionó sin intervención; consumo de cuota alto |
| 10 | Runner Antigravity CLI (agy) por proyecto | completada | 2026-07-17, 20 tests nuevos (56 total); pendiente piloto en vps-setup |

## Supuestos tomados por las personas

(ninguno)

## Bloqueos

- Piloto 2 pendiente en `odoo-reylub` (proyecto brownfield real); solo tras
  ese piloto hacer rollout al resto de PROYECTOS. Detalle en
  `docs/superpowers/plans/2026-07-16-capa-orquestacion-agf.md` (Task 9).
- Piloto del runner Antigravity pendiente en `vps-setup` (segunda feature,
  convirtiendo el proyecto de claude a agy). Verificar en ese piloto:
  (a) que `agy` lee el snippet de `AGENTS.md` y los skills BMAD instalados
  con el tool ID `gemini` (`.agents/skills`) — si no, probar el ID
  `antigravity` (`.agent/skills`); (b) que el hook Stop en
  `.agents/hooks.json` bloquea de verdad con `{"decision":"deny"}` (el
  contrato se tomó de docs de terceros, no está probado en vivo); (c) al
  convertir, quitar a mano el bloque AGF de `CLAUDE.md` si se quiere que
  `agf start` no tenga ambigüedad (AGENTS.md tiene prioridad de todos modos).

## Métricas del ciclo

- Ciclos completados sin intervención: 1 (Piloto 1 en vps-setup, greenfield)
- Stories rechazadas por QA: 0
- Notas de consumo de cuota: Piloto 1 consumió mucha cuota Pro (esperado por
  la autonomía del ciclo); evaluar mitigaciones antes del rollout

## Última sesión

- Fecha: 2026-07-17
- Resumen: Story 9a completada — instalación validada end-to-end en un
  sandbox git (scratchpad): `install.sh` con BMAD real v6.10.0 (46 skills),
  PROJECT-STATE.md creado con nombre sustituido, snippet AGF en CLAUDE.md
  (idempotente, 1 marcador tras 2ª pasada), hook Stop registrado en
  `.claude/settings.json`, proyecto visible en `agf status`. Hooks probados
  en vivo: Stop bloquea (exit 2) con tree sucio sin tocar estado y pasa al
  actualizarlo; phase-gate bloquea `arquitectura` sin PRD y desbloquea con
  él. Nota: un PROJECT-STATE.md sin trackear cuenta como "actualizado"
  (aparece en porcelain) — comportamiento aceptado, solo aplica hasta el
  primer commit tras instalar.
- Actualización 2026-07-17 (tarde): Piloto 1 completado en `vps-setup`
  (proyecto greenfield elegido por Angel). Funcionó "a la perfección" sin
  intervención; consumo de cuota alto. Symlink `agf` creado en ~/.local/bin.
- Actualización 2026-07-17 (2): Story 10 implementada — runner Antigravity
  por proyecto: `install.sh --runner antigravity` (BMAD tool `gemini`,
  snippet en AGENTS.md, hook Stop adaptado en `.agents/hooks.json`),
  `hooks/update-state-agy.sh` (contrato agy: exit 0 + JSON allow/deny),
  `agf start` detecta el runner por proyecto, `install.sh` crea el symlink
  de agf. Suite: 56 tests en verde.
- Siguiente paso: piloto del runner agy en `vps-setup` (segunda feature) y
  Piloto 2 en `odoo-reylub`.
