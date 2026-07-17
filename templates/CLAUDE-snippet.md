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
