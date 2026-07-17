# Tarjetas — Misión: [NOMBRE CORTO]

Tarjetas listas para Jira. Cada tarjeta es pequeña, entregable y trazable a los CA que
valida. Los casos de prueba de tarjeta son puntuales; los de misión (flujos completos)
viven en `05-pruebas.md`. Si hay MCP de Atlassian conectado, crear estas tarjetas en el
proyecto Jira del equipo tras aprobación humana.

Convención de orden: primero fundaciones (modelo de datos, migraciones con rollback),
luego lógica, luego UI, luego instrumentación y mallas. Marcar `[P]` las paralelizables
en worktrees.

---

## T-01 · [Título en verbo: "Crear modelo X con migración reversible"]
- **Contexto:** [una o dos líneas; referencia a sección del plan]
- **Cubre:** RF-01 → CA-01, CA-02
- **Entregable:** [qué queda funcionando/observable]
- **Pruebas (TDD primero):** tests que se escriben ANTES del código, derivados de los CA
- **Definition of Done:**
  - [ ] Tests escritos antes del código y en verde (red-green-refactor)
  - [ ] CA cubiertos verificados
  - [ ] Migración con rollback probado (si aplica)
  - [ ] Suite del proyecto verde
  - [ ] Documentación/README del módulo actualizado (si aplica)
- **Estimación:** [S / M / L]
- **Dependencias:** [T-xx o "ninguna"] · **Paralelizable:** [Sí [P] / No]

## T-02 · […]
…

---

## Cierre de misión (tarjetas obligatorias)
- **T-XX · Instrumentación de métricas** — eventos/paneles para los criterios de éxito.
- **T-XX · Malla de seguridad** — si se tocan datos críticos (ver 05-pruebas.md).
- **T-XX · Verificación E2E** — flujo completo en browser + `/simplify` + PR.
- **T-XX · Feature flag** — alta de `[nombre_ff]`, plan de rollback y (post-100%) tarjeta
  de eliminación de la FF.
