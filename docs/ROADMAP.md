# Ideas pendientes

Nada de esto está hecho. Ordenado de más fácil a más costoso.

1. **Quitar el código muerto de Drive** (`renderDrive`, `normFiles`, `S.drive`) de `dashboard/your-nymiz.html`.
2. **Filtrar boletines del correo:** limitar a remitentes `@example.com` o excluir remitentes concretos en la consulta de Gmail.
3. **Logo oficial de Nymiz** en la barra: pasar el SVG o PNG del logo y convertirlo en la imagen plantilla de `makeStatusIcon()` (o cargarlo desde `Contents/Resources` con `isTemplate = true`).
4. **Contador en el icono del fantasma** sin credenciales nuevas: que la página envíe el número de pendientes a la app con `window.webkit.messageHandlers.yourNymiz.postMessage(n)` y que la app lo reciba con un `WKScriptMessageHandler` y lo pinte junto al icono. Ojo: el panel corre dentro de un iframe de claude.ai, así que habría que comprobar que el mensaje llega desde el iframe.
5. **Sincronizar las marcas de visto** entre dispositivos usando la base de datos del artifact (capacidad `db` + `user` para datos privados por usuario).
6. **Más fuentes:** Jira (tienes tickets asignados que llegan por correo), Notion o HubSpot, si se conectan en Ajustes → Conectores.
7. **App nativa completa** con OAuth propio de Google y Slack, si se quiere que funcione sin claude.ai. Requiere credenciales en Google Cloud y aprobación de una app de Slack.
