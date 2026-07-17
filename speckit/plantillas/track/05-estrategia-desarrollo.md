# 🧠 Estrategia de desarrollo — Track
El slicing maximiza el VALOR ACUMULADO entregado, no divide trabajo. Producto: capacidad
real usable. Técnico: mejora observable (performance, estabilidad, velocidad). Pregunta
guía: ¿cuál es el primer entregable que demuestra valor EN PRODUCCIÓN? Excepciones de
base técnica profunda requieren justificación explícita con datos.

## Criterio de slicing
Opciones: por proceso de negocio · por segmento de usuario · por geografía · por canal ·
por complejidad funcional. Debe ser consistente con el esfuerzo técnico.
**Criterio elegido:** [cuál y por qué maximiza valor en este track]

## Misiones propuestas
⚠️ Solo las primeras 2–3: habrá aprendizajes que cambien el rumbo.
| Orden | Nombre | Descripción (qué valor y para quién) | Lanzamiento |
|---|---|---|---|
| 1 | [nombre] | […] | Pilotos / Todos |
| 2 | [nombre] | […] | Pilotos / Todos |

## Estrategia técnica de rollout
- Feature flags por segmento (tenant, país, tamaño)
- Mecanismos de rollback sin pérdida de datos ni downtime
- Gestión de migraciones sin disrupción y con rollback
- Estrategia de limpieza de deuda (¿cuándo se eliminan las FF?)
