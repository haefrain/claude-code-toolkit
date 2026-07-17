# 🧬 Técnica — Track
Arquitectura propuesta y modelo de datos global. Menos detalle que la técnica de cada
misión: el track declara lineamientos; la profundidad va en cada misión. Excluye casos
borde, tarjetas, plan de pruebas, bugs y documentación de usuario.

## 1 · Especificación de la solución elegida
> Antes de especificar: alternativas reales evaluadas y documentadas en 04-alternativas.md.

### Descripción de la solución
[Cubriendo RF y RNF declarados. Basada en el estado actual del código del repo.]

### Diagramas de diseño
ER, flujo, secuencias, componentes — con fuente editable (mermaid aquí o link). Nuevos
elementos destacados.
```mermaid
%% [PENDIENTE]
```

### Contratos e integraciones externas (opcional)
Solo BBs compartidos o contratos de consumo externo (LMS, APIs de terceros). Contratos
front-back de una misión acotada van en la técnica de esa misión.
| Qué se modifica/expone | Quién consume | Frecuencia/volumen |
|---|---|---|

### Infraestructura (opcional)
¿Apoyo de SRE? ¿Cambios de infra? ¿Informados y validados?

### Herramientas de adopción (opcional)
Solo si el track crea componentes nuevos o toca core: clasificar como Skills
(entendimiento profundo) o Comandos (pasos determinísticos).

## 2 · Riesgos técnicos
| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
Si hay migraciones: garantía de corrección, ejecución en tiempo y sin efectos secundarios.

## 3 · Instrumentación para métricas
Cómo se medirá lo que negocio define como criterios de éxito + instrumentación para
operar con confianza. (Las métricas en sí viven en 01-negocio.md.)
