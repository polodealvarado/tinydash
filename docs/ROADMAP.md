# Ideas pendientes

Nada de esto está hecho. Ordenado de más fácil a más costoso.

1. **Filtrar boletines del correo:** limitar a remitentes `@example.com` o excluir remitentes concretos en la consulta de Gmail.
2. **Logo oficial de Nymiz** en la barra: pasar el SVG o PNG del logo y convertirlo en la imagen plantilla de `makeStatusIcon()` (o cargarlo desde `Contents/Resources` con `isTemplate = true`).
3. **Contador en el icono del fantasma:** con la v2 la app ya tiene los datos; basta con contar pendientes en `sync()` y poner `statusItem.button?.title`.
4. **Avisos de recordatorios:** notificación de macOS (`UNUserNotificationCenter`) cuando vence una tarea.
5. **Sincronizar las marcas de visto** entre dispositivos (hoy viven en el `localStorage` de este Mac).
6. **Más fuentes:** Jira, Notion o HubSpot, con sus APIs.
