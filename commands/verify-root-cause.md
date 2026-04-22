---
description: Verifica causa raíz antes de tocar código — callers, escrituras, usos reales.
argument-hint: "<símbolo|path:función|endpoint>"
---

Aplica el protocolo de verificación de causa raíz de CLAUDE.md (caso ReclamaAI #46 / #48).

Entrada: `$ARGUMENTS` — puede ser un nombre de función, un path, o un endpoint.

Ejecuta estas verificaciones en paralelo con Grep/Bash:

1. **Callers de la función**: `grep -rn "<nombre>(" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" --include="*.php"`. Si 0 callers → **código muerto**, reporta y detente.
2. **Imports del símbolo**: `grep -rn "import.*<nombre>" --include="*.ts"`
3. **Puntos de escritura** (si es un campo/columna): `grep -rn "<campo>:" --include="*.ts" app/ lib/ src/`
4. **Si es endpoint**: leer el archivo del route handler completo.
5. **Tests que lo cubren**: `grep -rn "<nombre>" __tests__ tests/ spec/`

Reporta:

```
## Verificación de causa raíz — <símbolo>

- Callers: <N>  (lista de archivos)
- Imports: <N>
- Puntos de escritura: <N>
- Tests: <N>

### Diagnóstico
<una de: "código muerto", "usado en X puntos", "endpoint activo", "requiere análisis manual">

### Recomendación
<tocar solo X, o crear issues separados por cada punto de escritura, o reclasificar>
```

**Nunca escribas código tras este comando. Solo diagnóstico.**
