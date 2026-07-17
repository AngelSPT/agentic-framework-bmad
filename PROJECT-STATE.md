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
| 9b | Piloto 1: ciclo completo en proyecto real | pendiente | ver "Bloqueos" |

## Supuestos tomados por las personas

(ninguno)

## Bloqueos

- **Story 9b pendiente: prueba piloto en proyecto real.** La instalación ya
  está validada en sandbox (Story 9a), pero falta correr una feature real
  pequeña por el ciclo completo (PRD → arquitectura → stories →
  implementación → QA) y registrar las 4 métricas del spec: ¿terminó sin
  intervención?, cuota consumida, ¿respetó la arquitectura?, ¿retomar
  costó < 2 min?
  - Requiere input de Angel: elegir proyecto piloto (`pruebas` o
    `social-media-content-generator`) y la feature.
  - Tras el Piloto 1: Piloto 2 en `odoo-reylub`, y solo entonces rollout al
    resto de PROYECTOS. Detalle completo en
    `docs/superpowers/plans/2026-07-16-capa-orquestacion-agf.md` (Task 9).

## Métricas del ciclo

- Ciclos completados sin intervención: 0 (aún sin piloto)
- Stories rechazadas por QA: 0
- Notas de consumo de cuota: —

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
- Siguiente paso: Story 9b (Piloto 1) cuando Angel elija proyecto y feature.
