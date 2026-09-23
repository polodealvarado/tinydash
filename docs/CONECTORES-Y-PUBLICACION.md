# Conectores y publicación

## Conectores que usa el panel

Se gestionan en claude.ai → **Ajustes → Conectores**, con tu cuenta `user@example.com`.

| Conector | Estado | Notas |
|---|---|---|
| Google Calendar | Conectado | La primera conexión se hizo sin permiso de lectura y daba `Insufficient scope`. Se arregló reconectando y aceptando todos los permisos. |
| Gmail | Conectado | Mismo problema y misma solución que Calendar. |
| Slack | Conectado (espacio `nymiz`) | Necesitó la aprobación del administrador de Slack. Tu ID de usuario es `U00000000`. |
| Google Drive | Conectado, pero el panel ya no lo usa | La sección "Compartido contigo" se quitó a petición tuya. |

Si una sección muestra "is connected without read access" o "session expired", reconecta ese conector en Ajustes → Conectores y acepta todos los permisos.


## Manifiesto de capacidades

El artifact declara qué conectores y herramientas puede llamar. **Tiene que coincidir con lo que llama la página.** Si la página empieza a usar una herramienta nueva, hay que añadirla aquí al publicar:

```json
{
  "mcp": {
    "servers": [
      { "server": "Google Calendar", "tools": ["list_events"] },
      { "server": "Gmail",           "tools": ["search_threads"] },
      { "server": "Slack",           "tools": ["slack_search_public_and_private"] }
    ]
  }
}
```

## Cómo publicar cambios del panel

Claude Code puede editar `dashboard/your-nymiz.html`, pero no publicar Artifacts de claude.ai desde tu terminal. El flujo es:

1. Edita y guarda `dashboard/your-nymiz.html` (a mano o con Claude Code).
2. En claude.ai o Cowork, pide a Claude algo como: *"Republica ~/Documents/your-nymiz/dashboard/your-nymiz.html en https://example.com/dashboard"*, y dile si cambia el manifiesto.
3. Claude lee el archivo, lo publica en la **misma URL** (no cambia el enlace) y la app de la barra muestra la nueva versión al pulsar Refresh.

Reglas al editar la página:

- Sin `<!doctype>`, `<html>`, `<head>` ni `<body>`; el `<title>` al principio del archivo.
- Scripts externos solo desde cdnjs.cloudflare.com o cdn.jsdelivr.net; estilos externos solo de Google Fonts. Nada de `fetch` a otros sitios.
- No uses `alert()`, `confirm()` ni `prompt()`; en el visor no funcionan.
- Todo acceso a `localStorage` dentro de try/catch.
- Probar en local solo sirve para el diseño: fuera de claude.ai no hay acceso a conectores y verás el mensaje "This view can't read your connectors".

## Cómo actualizar la app de la barra

1. Cambia `macos-app/main.swift` y sube la versión en `macos-app/Info.plist` (`CFBundleShortVersionString` y `CFBundleVersion`).
2. `cd macos-app && ./build.sh`. Compila, cierra la versión que esté abierta, instala en /Applications y la abre.

Si solo cambia el panel, no hace falta recompilar la app: carga siempre la URL publicada.
