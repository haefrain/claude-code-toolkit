# Verificación — Sección 01 (guía 2026)

**Principio (tip #1 del equipo de Claude Code):** si Claude puede comprobar su propio trabajo, itera hasta que esté bien. Sin verificación, el usuario es el ciclo de feedback.

## Reglas duras

1. **Evidencia antes de afirmaciones.** Nunca declarar algo terminado sin comando corrido + salida real. «Debería funcionar» está prohibido. Si los tests fallan, decirlo con la salida.
2. **Cierre estándar:** todo cambio no trivial termina con `/simplify` antes de entregar.
3. **Regla de oro (compounding):** tras cada corrección de Efraín, actualizar el CLAUDE.md del repo para no repetir el error. Claude escribe la regla, Efraín la aprueba.
4. **Frontend:** verificar en browser real (extensión de Chrome de Claude Code) cuando esté disponible — no solo tests.
5. **El hook Stop corre `.claude/verify.sh`** del repo cuando hubo código editado. Si falla, Claude sigue trabajando (máx. 2 reintentos). No intentes evadirlo: arreglá la causa.

## Contrato por repo

- `.claude/verify.sh` — modo rápido (< 5 min) siempre; `FULL=1 bash .claude/verify.sh` corre la suite completa.
- Repo sin contrato → crearlo con `/verify-setup` (detecta stack, usa plantillas de `~/.claude/templates/verify/`).
- Repos `haefrain/*`: el contrato se comitea. Repos ajenos (bukhr/*): local + `.git/info/exclude`.
- Tercer nivel: `MUTATION=1 bash .claude/verify.sh` — mutation testing (Infection PHP / Stryker JS-TS / mutant Ruby): mide que los tests realmente maten mutantes (MSI), no que solo pasen. Lento por diseño: usarlo antes de PRs importantes o en jobs nocturnos, nunca en el gate rápido del Stop.

## Prompts del repertorio (usarlos y auto-aplicarlos)

- «**Demuéstrame que esto funciona**» — comparar comportamiento entre main y la rama antes de declarar listo.
- «**Examíname sobre estos cambios** y no abras el PR hasta que pase tu examen.»
- Tras un primer intento mediocre: «con todo lo que sabes ahora, **bota esto e implementa la solución elegante**».
