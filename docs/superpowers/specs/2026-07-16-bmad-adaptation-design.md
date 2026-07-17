# Adaptación de BMAD Method al flujo de trabajo multi-proyecto — Diseño

**Fecha:** 2026-07-16
**Estado:** Aprobado en brainstorming, pendiente de plan de implementación

## Contexto y problema

Angel gestiona múltiples proyectos de cliente en paralelo (perfil MSP): Odoo
(`odoo-projects`, `odoo-reylub`), web (`GMSPWEB`, `gigatechmsp`), FastAPI y
herramientas internas, todos bajo `~/PROYECTOS/`. El dolor principal es la
**imposibilidad de paralelizar**: todo el trabajo con Claude Code pasa por una
sola sesión secuencial, y cambiar de proyecto implica reconstruir contexto
manualmente en cada sesión.

Requisitos confirmados durante el brainstorming:

| Decisión | Valor elegido |
|---|---|
| Dolor principal | Paralelismo **entre proyectos** (no dentro de un repo) |
| Alcance | Todos los proyectos de PROYECTOS, presentes y futuros |
| Plan de Claude | **Claude Pro** (cuota ajustada — restricción dura de diseño) |
| Ceremonia | **BMAD completo**: PRD, arquitectura, user stories, personas |
| Supervisión | **Fire-and-forget**: definir la feature y revisar al final |
| Herramienta | Todo el ciclo en **Claude Code** (sin planificación en Claude.ai) |

## Arquitectura: dos piezas con responsabilidades separadas

### Pieza 1 — BMAD-METHOD oficial (v6.x), instalado por proyecto

Cada repo recibe la instalación estándar no interactiva:

```bash
npx bmad-method install --directory <repo> --modules bmm --tools claude-code --yes
```

BMAD es dueño de la **metodología**: personas (Analyst/PM, Architect, Dev, QA,
Scrum Master), workflows y artefactos (PRD, arquitectura, stories), que viven
dentro de cada repo. No se modifica el framework — solo se configura — para
recibir upgrades de la comunidad sin fricción.

### Pieza 2 — `agentic-framework`: capa de orquestación propia (lo que se construye)

```
agentic-framework/
├── bin/agf                  # CLI launcher multi-proyecto (bash + tmux)
├── templates/
│   ├── PROJECT-STATE.md     # estado vivo por proyecto (memoria entre sesiones)
│   └── CLAUDE-snippet.md    # reglas estándar añadidas al CLAUDE.md de cada repo
├── hooks/
│   ├── update-state.sh      # hook Stop: actualiza PROJECT-STATE.md al cerrar sesión
│   └── phase-gate.sh        # bloquea una fase si falta el artefacto de la anterior
└── install.sh               # bootstrap: instala BMAD + enlaza hooks y plantillas
```

Componentes:

- **`bin/agf`** — CLI en bash sobre tmux. `agf start <proyecto...>` abre una
  ventana tmux por proyecto, cada una corriendo Claude Code en su repo.
  `agf status` muestra la fase y pendientes de cada proyecto leyendo los
  `PROJECT-STATE.md` (bash puro, cero tokens). Se elige tmux puro sobre
  CCManager/Claude Squad porque el paralelismo es entre repos distintos (no se
  necesitan worktrees), son ~100 líneas controlables, y evita depender de
  herramientas de terceros sensibles a cambios de política de Anthropic.
- **`templates/PROJECT-STATE.md`** — un archivo por proyecto con: feature
  activa, fase BMAD actual, stories completadas/pendientes/bloqueadas,
  supuestos tomados por las personas, y métricas de consumo. Es la memoria
  persistente que hace que retomar un proyecto cueste una lectura de archivo.
- **`templates/CLAUDE-snippet.md`** — reglas de frugalidad y del ciclo que se
  añaden al CLAUDE.md de cada repo (ver más abajo).
- **`hooks/update-state.sh`** — hook `Stop` de Claude Code: al terminar una
  sesión, asegura que `PROJECT-STATE.md` refleje el estado real.
- **`hooks/phase-gate.sh`** — valida que exista el artefacto de la fase
  anterior antes de permitir la siguiente (no hay código sin story, ni story
  sin PRD). Falla *cerrado*: si no puede leer el artefacto, bloquea.
- **`install.sh`** — bootstrap de un repo: corre el instalador de BMAD y
  enlaza hooks/plantillas. Idempotente.

## Flujo de trabajo por feature (100% en Claude Code)

1. **Kickoff**: en la sesión del proyecto, Angel describe la feature (una
   frase o un párrafo). Es todo su input obligatorio.
2. **Planificación fire-and-forget**: las personas PM y Architect corren como
   **subagentes** — cada una en su propia ventana de contexto, devolviendo a
   la sesión principal solo el artefacto terminado (PRD → arquitectura →
   stories). Si el PM detecta ambigüedad, anota sus supuestos en el PRD y
   continúa; los supuestos quedan visibles para revisión posterior, no
   bloquean.
3. **Implementación + QA**: Dev implementa story por story; QA valida cada
   una contra el PRD **y** el doc de arquitectura antes de marcarla completa.
   `phase-gate.sh` impide avanzar sin artefacto previo.
4. **Cierre**: `update-state.sh` deja `PROJECT-STATE.md` al día; Angel revisa
   resultados y artefactos cuando el ciclo termina.

### Flujo diario multi-proyecto

- Mañana: `agf start <proyectos-del-día>` → una ventana tmux por proyecto.
- Se dispara un ciclo fire-and-forget en cada ventana según prioridad.
- `agf status` para supervisar sin gastar tokens; revisión de resultados al
  terminar cada ciclo.

## Reglas de frugalidad (cuota Pro)

1. **Personas siempre como subagentes**, nunca conversando en la sesión
   principal. Prohibido el "Party Mode" de BMAD (multi-persona en una sesión).
2. **Máximo 2 ciclos fire-and-forget simultáneos** en Claude Code (regla
   dura). Un tercer proyecto espera; quedarse sin cuota a mitad de dos
   implementaciones es el peor resultado posible.
3. **Sonnet por defecto** para todas las personas del ciclo; el modelo grande
   se reserva para las intervenciones manuales de Angel.
4. **Artefactos con límite de tamaño** definido en las plantillas (PRD ~2
   páginas): se leen en cada fase, así que su tamaño multiplica el costo.

## Manejo de errores

Principio: **ningún fallo pierde trabajo, porque el estado vive en archivos.**

- **Cuota agotada a mitad de ciclo**: cada story completada se marca en
  `PROJECT-STATE.md` *antes* de empezar la siguiente. Relanzar el mismo
  comando retoma desde la última story confirmada.
- **QA rechaza 2 veces la misma story**: el ciclo se detiene y registra la
  story bloqueada, el motivo y lo que intentó Dev. Señal de intervención
  humana; no se reintenta a ciegas.
- **Desviación de arquitectura**: QA valida conformidad con el doc de
  arquitectura, no solo funcionamiento — el gate contra el riesgo clásico del
  fire-and-forget.
- **Hooks defensivos**: `phase-gate.sh` falla cerrado.

## Plan de validación (antes del rollout general)

1. **Piloto 1** en un proyecto de bajo riesgo (`social-media-content-generator`
   o `pruebas`): una feature real pequeña por el ciclo completo.
2. **Métricas del piloto** (registradas en su `PROJECT-STATE.md`):
   - ¿El ciclo terminó sin intervención humana?
   - Cuota consumida por una feature típica (calibra la regla de 2 ciclos).
   - ¿El código respetó el doc de arquitectura?
   - ¿Retomar la sesión al día siguiente costó menos de 2 minutos?
3. **Piloto 2** en `odoo-reylub`: valida que las plantillas absorben el
   contexto delicado de Odoo (DB compartida, convenciones de módulos) vía
   CLAUDE.md.
4. **Rollout**: solo tras ambos pilotos, `install.sh` al resto de PROYECTOS.

## Fuera de alcance

- Worktrees y paralelismo dentro de un mismo repo (no es el dolor actual).
- Agent Teams / swarms multi-agente en un repo (incompatible con cuota Pro).
- Planificación en Claude.ai vía web bundles (descartado: se prefiere flujo
  directo en Claude Code).
- Integración con GitHub Issues estilo CCPM (posible evolución futura).
- Dashboards de monitoreo (Mission Control u otros): `agf status` es
  suficiente para esta escala.

## Criterios de éxito

- Retomar cualquier proyecto cuesta < 2 minutos de contexto.
- 2 proyectos avanzan en paralelo en un día de trabajo normal sin agotar la
  cuota Pro antes del final de la jornada.
- Una feature pequeña atraviesa el ciclo completo (PRD → código validado por
  QA) sin intervención humana.
- Instalar el framework en un proyecto nuevo cuesta un solo comando.
