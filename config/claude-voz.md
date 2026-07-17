# Modo voz bidireccional — Sección 02 (guía 2026)

Efraín quiere interactuar voz a voz: él dicta, y Claude le HABLA de vuelta las definiciones, planes y resultados. La entrada de voz es de Efraín (`/voice`, dictado fn-fn); la salida es responsabilidad de Claude con el TTS de macOS.

## Cuándo hablar

- **Solo si el modo está activo:** existe `~/.claude/voz-on` (lo gestiona `/voz on|off`). Sin marcador → cero audio, comportamiento normal.
- Con el modo activo, al **final de cada respuesta sustantiva** (resultado de tarea, plan presentado, hallazgo, decisión tomada): hablar un resumen.
- NO hablar en: respuestas triviales de una línea, listados intermedios, actualizaciones de progreso entre tool calls, o si Efraín pidió silencio temporal.

## Cómo hablar

- Comando (SIEMPRE en background — `run_in_background: true` — para no bloquear el turno):

```bash
say -v "$(cat ~/.claude/voz-on 2>/dev/null || echo Paulina)" "<texto>"
```

- **Resumen por defecto:** 1–3 frases en español natural, sin markdown, sin rutas ni símbolos leídos letra a letra (describir: «el script de verificación», no «scripts slash verify guión stop punto ese hache»). Números y porcentajes sí.
- **Versión detallada:** si Efraín dice «detallada», «dímelo completo» o similar → hablar la versión completa de la última respuesta, limpiada para audio (sin bloques de código; describir qué hace el código en su lugar).
- Preguntas al usuario: si la respuesta termina en una pregunta o decisión pendiente, el resumen hablado DEBE incluirla — es lo más importante de escuchar.
- El texto escrito NO se recorta: la respuesta completa siempre queda en pantalla; el audio es un complemento.

## Reglas de higiene

- Nunca hablar contenido sensible (tokens, credenciales, datos personales de terceros).
- Si `say` falla (volumen, permisos), seguir en silencio — jamás romper el flujo por el audio.
- Voz por defecto: **Paulina** (es-MX). Cambiar con `/voz <nombre>` (Mónica es-ES también instalada).
