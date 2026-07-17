# Verificación — Sección 01 (guía 2026)

**Principio (tip #1 del equipo de Claude Code):** si Claude puede comprobar su propio trabajo, itera hasta que esté bien. Sin verificación, el usuario es el ciclo de feedback.

## Reglas duras

1. **Evidencia antes de afirmaciones.** Nunca declarar algo terminado sin comando corrido + salida real. «Debería funcionar» está prohibido. Si los tests fallan, decirlo con la salida.
2. **Cierre estándar:** todo cambio no trivial termina con `/simplify` antes de entregar.
3. **Regla de oro (compounding):** tras cada corrección de Efraín, actualizar el CLAUDE.md del repo para no repetir el error. Claude escribe la regla, Efraín la aprueba.
4. **Frontend:** verificar en browser real (extensión de Chrome de Claude Code) cuando esté disponible — no solo tests.
5. **El hook Stop corre `.claude/verify.sh`** del repo cuando hubo código editado. Si falla, Claude sigue trabajando (máx. 2 reintentos). No intentes evadirlo: arreglá la causa.

## Contrato por repo

- `.claude/verify.sh` — **gate por defecto en cada Stop**: lint + typecheck + tests enfocados + **mutación SOLO de los archivos afectados** (Infection PHP / Stryker JS-TS / mutant Ruby, por diff e incremental). Presupuesto `MUTATE_MAX_FILES=10`: si se excede, la mutación se difiere al cierre de la tarjeta con aviso. Los mutantes que cuentan son los de lo cambiado — la deuda pre-existente no bloquea.
- `FULL=1 bash .claude/verify.sh` — suite completa + build: **SOLO a solicitud explícita de Efraín. Claude jamás la corre proactivamente** (ni al Stop, ni como "cierre", ni por iniciativa propia).
- Repo sin contrato → crearlo con `/verify-setup` (detecta stack, usa plantillas de `~/.claude/templates/verify/`).
- Repos `haefrain/*`: el contrato se comitea. Repos ajenos (bukhr/*): local + `.git/info/exclude`.
- Repos con infra pesada de tests (docker, boots de minutos): la mutación del gate se comenta y se corre al cierre de tarjeta/PR — el Stop tiene timeout de 600s.
- ⚠️ **Frontera de confianza:** el contrato y el fallback son código del repo y se ejecutan automáticamente al Stop, fuera del sistema de permisos. En repos no confiables (clones de terceros), revisá `.claude/verify.sh` y los scripts de `package.json`/`composer.json` antes de trabajar con código.

## Prompts del repertorio (usarlos y auto-aplicarlos)

- «**Demuéstrame que esto funciona**» — comparar comportamiento entre main y la rama antes de declarar listo.
- «**Examíname sobre estos cambios** y no abras el PR hasta que pase tu examen.»
- Tras un primer intento mediocre: «con todo lo que sabes ahora, **bota esto e implementa la solución elegante**».
