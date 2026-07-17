# Plantilla técnica — Misión: [NOMBRE CORTO]

Complementa el doc técnico del track sin repetirlo. Si la misión no tiene track, los RF
se definen localmente con el mismo formato. Registrar decisiones ANTES de desarrollar.

> Gate de constitution: la solución debe ser coherente con RF/CA declarados, evaluar
> alternativas reales (sección 5), ser completable en ≤ 1 mes y no dejar ambigüedades.

## 1 · Especificación de la solución

### Descripción
[Solución técnica propuesta cubriendo requisitos funcionales y no funcionales. Basarse
en el estado ACTUAL del código: explorar el repo antes de escribir esta sección.]

### Diagramas de diseño
Fuente editable obligatoria (mermaid en este archivo o link a dbdiagram/mermaid.live).
Destacar entidades/columnas/componentes nuevos.

```mermaid
erDiagram
  %% [PENDIENTE: modelo de datos de la misión]
```

### APIs (opcional)
Solo si la misión modifica o expone endpoints/contratos hacia otros servicios:
| Qué cambia | Quién lo consume | Frecuencia/volumen relevante |
|---|---|---|

### Infraestructura (opcional)
¿Requiere apoyo de SRE o cambios de infra? ¿Ya fueron informados y validados?

## 2 · Riesgos técnicos (opcional)
Solo riesgos específicos de esta misión no cubiertos en el track. Si hay migraciones:
cómo se garantiza corrección, ejecución en tiempo y ausencia de efectos secundarios
(encolamiento de jobs, llamadas a APIs, bloqueo de tablas). Riesgos de negocio → tab GTM.

| Riesgo | Probabilidad | Impacto | Mitigación (y costo-beneficio) |
|---|---|---|---|

## 3 · Instrumentación para métricas (opcional)
Instrumentación necesaria para monitorear las métricas declaradas en la spec, solo si
esta misión la introduce o implementa la declarada en el track.

## 4 · Documentación
- Identificar documentación existente (packs, módulos, diagramas) que queda desactualizada.
- Actualizar README del pack/módulo afectado y documentar clases/servicios importantes.
- Enlaces a documentos actualizados para el revisor: [PENDIENTE]

## 5 · Alternativas de solución
Obligatoria si hay una decisión técnica no resuelta en el track. Evaluar en tres
dimensiones: valor al usuario, riesgo técnico y complejidad de mantenimiento.

| Alternativa | Valor | Riesgo técnico | Mantenimiento | Veredicto |
|---|---|---|---|---|
| A (elegida) |  |  |  | ✔ |
| B |  |  |  | ✘ porque… |

- ¿Se exploraron alternativas reales o solo variaciones de la misma idea?
- ¿Qué supuestos actuales podrían hacer que esta decisión cambie?

## 6 · Estrategia de delivery
- Worktree dedicado: `claude --worktree <mision-slug>`.
- Orden de implementación propuesto (dependencias entre tarjetas).
- TDD: cada tarjeta parte de los CA que cubre → tests primero.
- Verificación final: suite verde + browser (si UI) + pase de simplificación antes de PR.
