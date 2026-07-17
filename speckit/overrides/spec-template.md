# Misión: [NOMBRE CORTO]

[Nombre largo u objetivo de la misión] · v: 0.1
Track: [[docs/tracks/<track-slug>]] · Feature flag prevista: `[nombre_ff]` · Canal · Jira: [PENDIENTE]

> Instrucciones de llenado: leer primero los docs del track (negocio, requerimientos,
> técnica). No repetir lo que el track define; referenciarlo. Dejar `[PENDIENTE: …]`
> en todo dato de negocio que requiera definición humana. Español, tono BUK.

## 1 · Negocio (tab 01)

### Problema
Solo si es misión aislada; si pertenece a un track, referenciar el problema del track
y completar únicamente el scope. Explicar en dolores del usuario (user personas), no
en features, con ejemplos y evidencia (entrevistas, tickets, señales).

### Casos de uso
Subconjunto de casos del track que esta misión resuelve (total o parcialmente).

### Scope — [tarea + problema + aprendizaje] mínimo
- **Problema:** parte acotada del problema del track que se resuelve aquí.
- **Tarea (JTBD):** la tarea mínima que el usuario podrá realizar al terminar —
  expresada como tarea, no como feature.
- **Aprendizaje:** qué queremos aprender con esta misión.

### Criterios de éxito (QUÉ, CÓMO y CUÁNDO)
| Tipo | Métrica | Herramienta (amplitude, PAR, tickets, sentry) | Cuándo se mide |
|---|---|---|---|
| Pasar a siguiente misión | [PENDIENTE] | [PENDIENTE] | [PENDIENTE] |
| Revisión criterios del track | [PENDIENTE] | [PENDIENTE] | [PENDIENTE] |

**Otros aprendizajes buscados:** [que podrían hacer cuestionar el alcance del track]

## 2 · Requerimientos funcionales y solución (tab 01/track ref.)

| JTBD | Requerimiento funcional | Solución |
|---|---|---|
| JTBD-01 [tarea desde los zapatos del cliente] | RF-01 [qué debe lograr en la plataforma] | S-01 [cómo lo logrará] |
|  |  | S-02 […] |

## 3 · Criterios de aceptación (tab 02)

Comportamientos, reglas o capacidades verificables — qué información queda disponible y
cómo se comporta el sistema, sin detalles de implementación. Convención `CA-{correlativo}`
(se reinician por misión); cada CA cuelga de una solución `S-xx`.

### Funcionales
| Solución | Criterio de aceptación |
|---|---|
| S-01 | CA-01 [comportamiento verificable] |
| S-01 | CA-02 […] |

### No funcionales
Detallan los `RNF-xx` del track al nivel de esta misión; no crean RNF nuevos. La
descripción declara la condición MEDIBLE ("carga < 800 ms con 10.000 registros en
staging"), nunca la intención ("debe ser rápido").

**RNF-01 — [nombre]**
| ID | Criterio no funcional medible |
|---|---|
| RNF-01-CA-01 | [condición verificable en el contexto de esta misión] |

## Checklist de revisión (pre-plan)
- [ ] Scope expresado como tarea del usuario, no como feature
- [ ] Criterios de éxito con qué/cómo/cuándo y herramienta de medición
- [ ] Cadena JTBD → RF → S → CA completa y sin huecos
- [ ] CA-NF medibles y diferenciados de los funcionales
- [ ] Sin decisiones de stack ni detalles de implementación en este documento
