# Configuración (Google y Slack)

Desde la v2.0 la app lee Google Calendar, Gmail y Slack directamente, sin claude.ai. Hacen falta dos credenciales tuyas, una vez.

## Google (Calendar + Gmail)

1. Entra en https://console.cloud.google.com con tu cuenta de Google y crea un proyecto (p. ej. "Tinydash").
2. **APIs y servicios → Biblioteca:** activa **Gmail API** y **Google Calendar API**.
3. **Google Auth Platform → Público (Audience):** configura la audiencia adecuada para tu cuenta y los usuarios que usarán la app. Sigue la [guía oficial de OAuth para aplicaciones de escritorio](https://developers.google.com/identity/protocols/oauth2/native-app) y los requisitos de verificación que correspondan.
4. **Acceso a datos (Data access):** añade los permisos `.../auth/calendar.readonly` y `.../auth/gmail.readonly`.
5. **Clientes → Crear cliente →** tipo **App de escritorio (Desktop app)**. Copia el *Client ID* y el *Client secret*.
6. En la app, abre **Settings**, pega los dos valores y pulsa **Connect Google**. Se abre el navegador; acepta los permisos y verás "Signed in". La app sincroniza sola.

Si Workspace no te deja crear el proyecto o el cliente, lo tiene que permitir un administrador.

## Slack

1. https://api.slack.com/apps → **Create New App → From scratch**, en tu workspace.
2. **OAuth & Permissions → User Token Scopes:** añade `search:read`. Es el único permiso que hace falta.
3. **Install to Workspace.** Puede que lo tenga que aprobar un administrador.
4. Copia el **User OAuth Token** (`xoxp-…`), pégalo en **Settings → Slack** y pulsa **Save**.

## Periodo de consulta

En **Settings → Period → Number of days** puedes elegir de **1 a 365 días**. El valor inicial es **5**, incluido hoy. Pulsa **Save period** para guardar y volver a sincronizar las conexiones. El ajuste se conserva al cerrar la app y también funciona para tareas sin conectar Google o Slack.

- **Correo:** hilos sin leer de la bandeja de entrada dentro del periodo, con los filtros de categorías habituales. Hasta 25 hilos por sincronización.
- **Agenda:** siempre muestra solo los eventos de hoy, independientemente del periodo configurado, hasta 50 eventos. Incluye eventos que abarcan hoy aunque duren varios días. Las reuniones que ya terminaron se muestran como pasadas y no cuentan como pendientes.
- **Slack:** mensajes directos y menciones en el mismo periodo; hasta 20 mensajes directos y 15 menciones. Los mensajes directos se agrupan por conversación.
- **Tareas:** se usa la fecha de vencimiento o, si no existe, la de creación. **Show all** muestra también las tareas fuera del periodo. Filtrar no elimina tareas; **Clear done** solo elimina las completadas de la vista actual.

El periodo limita qué datos se consultan y muestran; no crea un archivo permanente de pendientes. Las marcas locales de correo y agenda siguen siendo diarias. Las marcas de Slack se conservan hasta 366 días.

## Editor de tareas

El campo de texto admite varias líneas, crece al escribir y se puede redimensionar verticalmente. **Expand** amplía el editor; **Compact** vuelve al tamaño reducido. **Enter** introduce un salto de línea; **⌘Enter** (o **Ctrl+Enter**) añade la tarea. Las tareas guardadas conservan los saltos de línea.

El borrador de texto y fecha se guarda localmente en el WebView mientras escribes y se recupera al volver a abrir el panel. Se elimina al añadir la tarea. El guardado depende de que el almacenamiento local esté disponible.

## Almacenamiento

| Qué | Dónde |
|---|---|
| Client ID/secret de Google, refresh token y token de Slack | Llavero de macOS, elemento `com.nymiz.yournymiz` |
| Tareas | `~/Library/Application Support/YourNymiz/tasks.json` |
| Última sincronización | `~/Library/Application Support/YourNymiz/sync.json` |
| Periodo de consulta | Preferencias de macOS (`UserDefaults`, clave `dashboardPeriodDays`) |
| Marcas de hecho/visto | `localStorage` del WebView (solo este Mac) |
| Borrador de tarea | `localStorage` del WebView, clave `tinydash-task-draft` |

**Aviso del llavero:** la app está firmada ad hoc, así que tras recompilar macOS puede pedir autorización para leer el llavero. Comprueba que la solicitud corresponde a la copia de Tinydash que has instalado.

Los identificadores de almacenamiento se conservan por compatibilidad. No son credenciales. No copies claves, tokens, capturas con datos personales ni archivos de estado al repositorio o a una incidencia pública.

## Sincronización

- Automática una vez al día: al abrir la app y, si no se ha sincronizado hoy, en la primera comprobación después de las 07:00. Comprueba cada 15 minutos y al despertar el Mac. Para cambiarlo, toca `SYNC_HOUR` y `AUTO_CHECK` en `main.swift`.
- Manual: el botón **Sync all** del panel, o clic derecho en el lápiz → **Sync now**.
