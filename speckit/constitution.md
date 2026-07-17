# Constitution — Proceso BUK (tracks y misiones)

Principios que gobiernan toda spec, plan, tarjeta e implementación en este repo.
`/speckit.analyze` y los revisores humanos validan contra este documento.

## I. Jerarquía Track → Misión
Toda misión pertenece a un track (salvo misiones aisladas justificadas). Antes de
especificar una misión, LEER los docs del track en `docs/tracks/<track>/` — en especial
negocio, requerimientos y técnica — y no repetir lo que el track ya define: la misión
referencia, no duplica. Cada fase cerrada actualiza la bitácora correspondiente.

## II. Slicing por valor
El objetivo del slicing es maximizar valor acumulado entregado, no dividir trabajo.
Cada misión debe poder completarse en ≤ 1 mes y apuntar a producción para clientes
reales (no demos internas). Proponer solo las próximas 2–3 misiones de un track.

## III. TDD innegociable
Toda tarjeta se implementa red-green-refactor: primero el test que falla (derivado de un
CA), luego el código mínimo que lo pasa, luego refactor. Ninguna tarjeta está "done" sin
sus tests escritos ANTES del código. Los casos de prueba CP referencian el CA que validan.

## IV. Verificación como gate
Claude debe poder verificar su propio trabajo: suite del proyecto verde, validación en
browser real para cambios de UI, y pase de simplificación/revisión (`/simplify` o
equivalente) antes de abrir PR. Un `Stop` hook con los checks del repo es el respaldo.
Trabajo sin verificación ejecutada = trabajo no terminado.

## V. Trazabilidad de IDs
Convenciones obligatorias: `JTBD-xx` (jobs to be done) → `RF-xx` (req. funcional) →
`S-xx` (solución) → `CA-xx` (criterio de aceptación) → `CP-xx` (caso de prueba).
RNF del track: `RNF-xx`; sus criterios en misión: `RNF-xx-CA-yy`. Los CA se reinician
por misión. Toda tarjeta cita los CA que cubre.

## VI. RNF antes de decisiones técnicas
Los requerimientos no funcionales (performance, seguridad, auditoría, escalabilidad,
mantenibilidad, compatibilidad, privacidad) se declaran en el track ANTES de decidir
arquitectura. Si aparece un RNF nuevo durante desarrollo, se registra antes de continuar.

## VII. Alternativas reales
Ninguna solución técnica se especifica sin haber evaluado alternativas reales (no
variaciones de la misma idea) en tres dimensiones: valor al usuario, riesgo técnico y
complejidad de mantenimiento. Documentar por qué las demás pierden y qué supuestos
harían cambiar la decisión.

## VIII. Rollout reversible
Feature flag por segmento cuando aplique, plan de rollback explícito (ojo con cambios de
modelo de datos), mallas de seguridad para datos críticos, olas de activación descritas
por características de clientes (no porcentajes ciegos). Activación al 100% es
obligatoria eventualmente y la FF se ELIMINA del código apenas se llegue: las FF son
deuda técnica temporal.

## IX. Diagramas con fuente editable
Todo diagrama (ER, flujo, secuencia) va en mermaid dentro del propio `.md` o con link a
fuente editable. Cambios nuevos se destacan. Un diagrama sin fuente editable no cumple.

## X. Idioma, formato y sincronización
Toda la documentación en español, tono BUK. Un archivo `.md` por tab del template
oficial. Al cerrar cada fase, sincronizar los tabs de la misión desde spec/plan/tasks
(skill `buk-mision`) y dejar `[PENDIENTE: …]` visible en lo que requiera definición
humana — nunca inventar datos de negocio, clientes o métricas.

## Gobernanza
Esta constitution prevalece sobre costumbres y prompts puntuales. Se modifica solo por
PR revisado. Cuando Claude cometa un error de proceso, la corrección se registra aquí o
en `CLAUDE.md` para que no se repita (ingeniería compuesta).
