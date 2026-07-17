# 📢 GTM y Roll-out — Misión

## a · Fases de roll-out
1. **Interno** (buk.buk, demos): stakeholders clave · monitoreo de riesgos · tiempo de feedback
2. **Clientes beta:** listado identificado por nombre/características (NO porcentaje) ·
   monitoreo de riesgos y criterios · entrevistas cualitativas · tiempo de medición
3. **Olas de activación:** segmentos descritos por características · nº de olas según
   riesgo · monitoreo · hitos a esperar (cierres de mes, procesos, X solicitudes)
4. **Activación al 100%:** obligatoria eventualmente, todos los segmentos y países
5. **Eliminación de FF:** apenas se llegue al 100% (misión, launchpad o misión del track) —
   las FF son deuda técnica temporal

## b · Riesgos (pre-mortem: "en 6 meses fue un fracaso, ¿por qué?")
Disrupción al cliente · valor no percibido · dependencias/equipos afectados.
**Mitigación:** usabilidad (criterios claros + roll-out corregible: ¡no seguir si hay
problemas!) · performance (plan de stress en staging/buk.buk, no "en local funcionaba") ·
errores (batería de pruebas compartida + malla de seguridad; si la malla falla, el caso
entra a la batería) · seguridad (involucrar equipos desde discovery).
**Plan de rollback:** cada paso reversible; ojo con cambios de modelo de datos (¿la
lógica antigua procesa los datos nuevos?) y resultados almacenados (identificar datos
generados por el flujo nuevo).

## c · Instrumentación
Cada riesgo con detección automática y objetiva (amplitude + baseline: tiempos de flujo,
uso del flujo nuevo).

## d · GTM dentro de la aplicación
Tour guiado (flujos nuevos) · ayuda contextual (tooltips, pop-overs) · opcionalidad de
activación (BB temporal para feedback) · coming soon.

## e · Checklist del revisor
- [ ] ¿Clientes/segmentos definidos por fase? · [ ] ¿FF nombrada, documentada y con rollback?
- [ ] ¿Umbrales cuantitativos por fase? · [ ] ¿Riesgos críticos con mitigación?
- [ ] ¿Dependencias y coordinaciones especificadas? · [ ] ¿Plan de rollback definido?

## Documentación de la misión
Capacitaciones · Buk Academy · publicación interna · artículos · ayuda contextual ·
material de Product Marketing.
