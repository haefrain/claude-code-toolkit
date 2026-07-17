# ✅ Pruebas — Misión
La calidad se incorpora ANTES del desarrollo. Los casos funcionales se generan desde los
CA (eso lo hace la IA con los criterios como contexto); documentar aquí solo lo que no
emerge de los CA: casos borde que requieren acuerdo explícito, no automatizables y
performance.

⚠️ **Mallas de seguridad:** si la misión modifica datos críticos o lógica de alto riesgo,
definir qué mallas validan que solo cambia lo que debe cambiar, si se reutilizan
existentes y cuándo corren. Idealmente la FF se activa condicionada a malla exitosa.

| ID | CA que valida | Entrada | Salida esperada | Riesgo | Tipo | Método |
|---|---|---|---|---|---|---|
| CP-01 | RF-01-CA-01 | [estado antes] | [qué es verdad después] | Alto/Medio/Bajo | Nuevo/Regresión | [k6 en staging…] |

> Diferencia con tarjetas Jira: aquí van flujos completos de punta a punta e integración
> entre tarjetas; en las tarjetas van validaciones puntuales durante el desarrollo.
