# Gestión de Issues — Referencia completa

## Inventario de projects vigentes (2026-04)

| # | Project | Repos cubiertos |
|---|---|---|
| 6 | VantLabs Corporativo | `vant-labs-corporative` |
| 7 | ReclamaAI Roadmap | `reclamaai`, `reclamaai-mobile` |
| 8 | VantLabs Financial | `infinite-studio-financial-app`, `infinite-studio-financial-api` |
| 9 | VantLabs Drive | `vantlabs-drive` |
| 10 | VantLabs Marketplace | `infinite-studio-marketplace` |

Si el repo no está listado: preguntar antes de crear project nuevo.

## Labels estándar

| Categoría | Labels |
|---|---|
| Asignación | `for:efrain`, `for:claude` |
| Severidad | `severity:critical`, `severity:high`, `severity:medium`, `severity:low` |
| Área | `area:gdpr`, `area:security`, `area:infra`, `area:payments`, `area:auth`, `area:ui`, `area:docs`, `area:database`, `area:ai`, `area:backups` |
| Plataforma | `platform:web`, `platform:mobile`, `platform:backend`, `platform:shared` |
| Estado | `blocked:external`, `needs-decision` |
| Tipo | `type:bug`, `type:feature`, `type:tech-debt`, `type:compliance` |

## Naming de issues

`[PREFIJO-NNN] Descripción en imperativo`

Prefijos: `GDPR-CRIT`, `GDPR-HIGH`, `GDPR-MED`, `GDPR-EFRAIN`, `DPA`, `PROD`, `TRACK`, `MOBILE`, `ADMIN`, `TYPES`, `OPS`, `DEBT`, `BUG`, `SEC`, `FEATURE`, `WA-WIZARD`

## Estructura mínima del body

```markdown
## Hallazgo / Qué hacer
## Por qué (norma / contexto)
## Criterios de aceptación
- [ ] acción verificable
## Bloquea / Bloqueado por
- Bloquea: #NN  |  Bloqueado por: #NN
## Referencias
- `path/file.ts:LINE`
```

## Checklist antes de crear un issue

1. ¿Causa raíz verificada con grep (no asumida)?
2. ¿Criterios de aceptación verificables (no vagos)?
3. ¿Todos los archivos con `path:line`?
4. ¿Dependencias bloqueantes declaradas?
5. ¿`for:efrain` vs `for:claude` claro? Si duda: dos issues.
6. ¿Salida de éxito objetiva?
7. ¿Alcance acotado? Si es enorme: épica + sub-issues.
8. ¿Función/endpoint mencionado realmente se usa? (grep antes)

**REGLA ReclamaAI #46:** antes de escribir un issue sobre función X, corre `grep -rn "X(" --include="*.ts"`. Si 0 callers → código muerto, el issue es distinto. Ver caso completo en CLAUDE.md principal.

## División for:efrain vs for:claude

**for:efrain:** config en Coolify/Vercel/Cloudflare, dashboards externos, decisiones estratégicas, firma de contratos, API keys, billing, pruebas en producción.

**for:claude:** escribir/modificar código, migraciones Prisma, docs en repo, auditorías, scripts, tests, refactors, issues.

Tarea mixta → dos issues con `Bloquea`/`Bloqueado por`.

## Comandos de referencia

```bash
gh issue list --repo <owner/repo> --label "for:claude" --state open --limit 20
gh issue create --repo <owner/repo> --title "[PREFIJO-NNN] ..." --body "..." --label "severity:high,for:claude,type:bug"
gh project item-add <N> --owner haefrain --url <issue-url>
gh issue close N --repo <owner/repo> --reason completed --comment "..."
gh search issues --owner haefrain --label "for:claude" --state open --sort created
```

## Reglas adicionales

**Toggles/switches con Efraín:** siempre indicar estado final inequívoco ("DEBE quedar en OFF"), explicar por qué, pedir confirmación visual. Si ya está correcto: "no toques nada". Caso originario: Sentry "Use of aggregated identifying data" 2026-04-07.

**Al cerrar un issue:** verificar que todos los criterios ✅ antes de `gh issue close`. Sub-tareas descubiertas → nuevos issues, no en el comentario de cierre.

**Lote de issues:** listar títulos primero, confirmar con Efraín, verificar duplicados con `gh issue list --search`, declarar dependencias antes de crear.

**Cuándo NO crear issue:** cambio trivial en sesión inmediata, exploración sin decisión, aclaración a issue existente (→ comentario).
