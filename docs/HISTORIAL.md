# Historial y decisiones

Todo se construyó con Claude (Cowork) el 23 de septiembre de 2026.

## Panel (artifact)

| Versión | Cambios |
|---|---|
| 1 | Primer panel "Radar del día" en español: agenda de Calendar, correo sin leer de Gmail, compartido contigo en Drive. Gmail y Calendar devolvían `Insufficient scope` (conectados sin permiso de lectura). |
| 2 | Tras reconectar Gmail y Calendar: enlace de Meet desde `conferenceUrl`, limpieza de entidades HTML y relleno en los fragmentos de Gmail, contador "25 de ~N" con `resultCountEstimate`. |
| 3 | Quitada la sección de Drive (y su permiso). Queda el código muerto `renderDrive`/`normFiles`. |
| 4 | Añadido Slack: mensajes directos de hoy agrupados por conversación y menciones en canales de los últimos 3 días, con la marca "Te pregunta". |
| 5 | Botón de check verde en Slack: marca como visto, lo quita de la lista, contador "N por ver" y opción Mostrar/Ocultar vistos. |
| 6 | Todo en inglés y nuevo título **Your Nymiz**. |

## App de la barra de menús

| Versión | Cambios |
|---|---|
| 1.0 | Icono con una "N" en un cuadrado; ventana flotante con el panel; menú con Refresh, Open in browser, Open at login y Quit. |
| 1.0 (icono) | El icono pasa a ser un fantasma (dibujado por Claude; no es el logo oficial de Nymiz). |
| 1.1 | Indicador de carga, mensajes de error, aviso de página vacía, opción Diagnostics… e inspector web. El diagnóstico mostró el fallo del login con Google. |
| 1.2 | Login con Google arreglado: su ventana emergente se abre como ventana real, el panel no se cierra mientras inicias sesión y vuelve solo al panel al terminar. |
| 2.0 (5/10/2026) | **Desacoplada de claude.ai.** El panel va dentro de la app (`dashboard/index.html`). La app usa OAuth propio de Google (Calendar y Gmail, solo lectura) y un token de usuario de Slack, guardados en el llavero. Sincroniza una vez al día y con **Sync all**. Nueva sección **Tasks** (tareas y recordatorios con fecha opcional, en `tasks.json`). Quitados el código muerto de Drive, el login de claude.ai y Diagnostics. |

| 2.1 (5/10/2026) | Rediseño del panel: identidad con fantasma, paleta lavanda y modo oscuro, tipografía del sistema sin descargas, contadores y navegación por Overview, Agenda, Tasks, Inbox y Slack. Tarjetas, formularios y estados vacíos más claros para la ventana de 460 px. |

| 2.2 (5/10/2026) | Renombrada a **Tinydash**, con un lápiz en el panel, en la barra de menús y como icono de la app. Repositorio `polodealvarado/tinydash`. Identificadores de almacenamiento y llavero conservados para mantener las conexiones y tareas. |

| 2.3.0 (5/10/2026) | Distribución Homebrew con paquete universal para Apple Silicon e Intel, checksum SHA-256, workflows de compilación y publicación, y guía de releases. Firma ad hoc; notarización pendiente de Apple Developer. |

## Decisiones

- **(v1, sustituida en la v2) La app abre el panel en vez de leer los datos ella misma.** Elegido para no tener que crear credenciales de Google Cloud ni otra app de Slack (que habría tenido que aprobar el administrador). Contrapartida: el icono no puede mostrar un contador de pendientes.
- **Drive:** se retiró la sección para reducir el alcance de la integración.
- **Marcas de visto y hecho en `localStorage`**, no en la base de datos del artifact: suficiente para un solo usuario en un solo navegador y sin configuración extra.
- **Interfaz en inglés**, documentación en español.
- **v2: sincronización diaria en vez de cada 5 minutos**, a petición tuya. El botón Sync all cubre el resto.
- **v2: la app hace las llamadas y el panel solo pinta.** Así los tokens no pasan nunca por JavaScript y no hay problemas de CORS.
