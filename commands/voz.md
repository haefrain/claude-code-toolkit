---
description: Activa/desactiva el modo voz bidireccional — Claude habla un resumen de cada respuesta con TTS de macOS. Uso; /voz on | off | estado | <nombre-de-voz>
argument-hint: "on | off | estado | <voz>"
---

Gestiona el modo voz bidireccional según el argumento (`$ARGUMENTS`):

## `on` (o sin argumento)

1. Activa el modo creando el marcador con la voz por defecto (o la ya configurada):

```bash
[[ -s ~/.claude/voz-on ]] || echo "Paulina" > ~/.claude/voz-on
```

2. Confirma HABLANDO (corre en background para no bloquear):

```bash
say -v "$(cat ~/.claude/voz-on)" "Modo voz activado. Te iré contando lo que hago."
```

3. A partir de ahora aplican las reglas de `~/.claude/claude-voz.md` (resumen hablado al final de cada respuesta sustantiva; versión detallada si Efraín la pide).

## `off`

```bash
rm -f ~/.claude/voz-on
```

Confirma por texto (ya sin audio): "Modo voz desactivado."

## `estado`

```bash
[[ -f ~/.claude/voz-on ]] && echo "ON — voz: $(cat ~/.claude/voz-on)" || echo "OFF"
```

## `<nombre-de-voz>` (p. ej. `Mónica`)

1. Verifica que la voz exista: `say -v '?' | grep -i "<nombre>"`. Si no existe, lista las disponibles en español (`say -v '?' | grep es_`) y no cambies nada.
2. Si existe: `echo "<nombre>" > ~/.claude/voz-on` y confirma hablando con la voz nueva.
