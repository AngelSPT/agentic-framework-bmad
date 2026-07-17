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
| 9 | Piloto 1: comprobación de instalación + prueba de ciclo completo | pendiente | ver "Bloqueos" |

## Supuestos tomados por las personas

(ninguno)

## Bloqueos

- **Story 9 pendiente de validación real (Task 9 del plan).** La suite de tests
  pasa (36/36) pero el framework NO está validado end-to-end. Falta:
  1. **Comprobación de instalación**: correr `./install.sh` sobre un proyecto
     piloto real (`pruebas` o `social-media-content-generator`, a decisión de
     Angel) y verificar que el instalador de BMAD termina bien, que existen
     `PROJECT-STATE.md`, el snippet en `CLAUDE.md` y el hook Stop en
     `.claude/settings.json`, y que el proyecto aparece en `agf status`.
  2. **Prueba piloto**: correr una feature real pequeña por el ciclo completo
     (PRD → arquitectura → stories → implementación → QA) y registrar las 4
     métricas del spec: ¿terminó sin intervención?, cuota consumida,
     ¿respetó la arquitectura?, ¿retomar costó < 2 min?
  - Requiere input de Angel (elegir proyecto y feature) y red (instala BMAD).
  - Tras el Piloto 1: Piloto 2 en `odoo-reylub`, y solo entonces rollout al
    resto de PROYECTOS. Detalle completo en
    `docs/superpowers/plans/2026-07-16-capa-orquestacion-agf.md` (Task 9).

## Métricas del ciclo

- Ciclos completados sin intervención: 0 (aún sin piloto)
- Stories rechazadas por QA: 0
- Notas de consumo de cuota: —

## Última sesión

- Fecha: 2026-07-16
- Resumen: Tasks 1-8 del plan implementadas vía subagentes (TDD, 36 tests en
  verde, HEAD 38c366f). jq 1.8.2 instalado en ~/.local/bin (sin sudo).
- Siguiente paso: ejecutar la Story 9 (comprobación de instalación + prueba
  piloto) cuando Angel elija proyecto y feature.
