# Historial y decisiones

Evolución técnica del panel y la aplicación de macOS.

## Panel (artifact)

| Versión | Cambios |
|---|---|
| 1 | Primer panel "Radar del día" en español: agenda de Calendar, correo sin leer de Gmail, compartido contigo en Drive. Gmail y Calendar devolvían `Insufficient scope` (conectados sin permiso de lectura). |
| 2 | Tras reconectar Gmail y Calendar: enlace de Meet desde `conferenceUrl`, limpieza de entidades HTML y relleno en los fragmentos de Gmail, contador "25 de ~N" con `resultCountEstimate`. |
| 3 | Quitada la sección de Drive (y su permiso). Queda el código muerto `renderDrive`/`normFiles`. |
| 4 | Añadido Slack: mensajes directos de hoy agrupados por conversación y menciones en canales de los últimos 3 días, con la marca "Te pregunta". |
| 5 | Botón de check verde en Slack: marca como visto, lo quita de la lista, contador "N por ver" y opción Mostrar/Ocultar vistos. |
| 6 | Interfaz en inglés y actualización del título. |

## App de la barra de menús

| Versión | Cambios |
|---|---|
| 1.0 | Icono con una "N" en un cuadrado; ventana flotante con el panel; menú con Refresh, Open in browser, Open at login y Quit. |
| 1.0 (icono) | Primer icono propio de la aplicación. |
| 1.1 | Indicador de carga, mensajes de error, aviso de página vacía, opción Diagnostics… e inspector web. El diagnóstico mostró el fallo del login con Google. |
| 1.2 | Login con Google arreglado: su ventana emergente se abre como ventana real, el panel no se cierra mientras inicias sesión y vuelve solo al panel al terminar. |
| 2.0 (5/10/2026) | **Desacoplada de claude.ai.** El panel va dentro de la app (`dashboard/index.html`). La app usa OAuth propio de Google (Calendar y Gmail, solo lectura) y un token de usuario de Slack, guardados en el llavero. Sincroniza una vez al día y con **Sync all**. Nueva sección **Tasks** (tareas y recordatorios con fecha opcional, en `tasks.json`). Quitados el código muerto de Drive, el login de claude.ai y Diagnostics. |

| 2.1 (5/10/2026) | Rediseño del panel: identidad con fantasma, paleta lavanda y modo oscuro, tipografía del sistema sin descargas, contadores y navegación por Overview, Agenda, Tasks, Inbox y Slack. Tarjetas, formularios y estados vacíos más claros para la ventana de 460 px. |

| 2.2 (5/10/2026) | Renombrada a **Tinydash**, con un lápiz en el panel, en la barra de menús y como icono de la app. Repositorio `polodealvarado/tinydash`. Identificadores de almacenamiento y llavero conservados para mantener las conexiones y tareas. |

| 2.3.0 (5/10/2026) | Distribución Homebrew con paquete universal para Apple Silicon e Intel, checksum SHA-256, workflows de compilación y publicación, y guía de releases. Firma ad hoc; notarización pendiente de Apple Developer. |

| 2.3.1 (5/10/2026) | Los contadores de agenda, resumen y reunión actual/próxima excluyen reuniones marcadas como hechas. El contador de la sección de correo coincide con sus pendientes de revisión local. Los contadores de Slack se actualizan al marcar como visto, antes de que termine la animación. Agenda, correo y tareas conservan las filas completadas para poder deshacer la marca. |

| 2.4.0 (5/10/2026) | Periodo configurable para correo, Slack, agenda y tareas, de 1 a 365 días con 5 por defecto. Preferencia persistente en macOS, actualización al guardar, fechas visibles en agenda y **Show all** para las tareas fuera del periodo. La caché registra el periodo consultado y las sincronizaciones solapadas se serializan. |

| 2.4.1 (6/10/2026) | Editor de tareas multilínea con crecimiento automático, Expand/Compact, redimensionado, atajo ⌘Enter y borrador local. Agenda vuelve a mostrar exclusivamente hoy; consulta y filtros locales excluyen otros días incluso con cachés anteriores. Correo, Slack y tareas mantienen el periodo configurable. |

| 2.4.2 (6/10/2026) | Retirada la casilla de hecho de la agenda. Los pendientes y Now/Next dependen del horario; se ignoran las marcas antiguas de calendario. |

| 2.4.3 (6/10/2026) | Las tareas pendientes siempre son visibles, incluso con vencimiento futuro. El periodo solo filtra las completadas, evitando que tareas guardadas parezcan no haberse añadido. |

## Decisiones



- **(v1, sustituida en la v2) La app abre el panel en vez de leer los datos ella misma.** Elegido para no tener que crear credenciales de Google Cloud ni otra app de Slack (que habría tenido que aprobar el administrador). Contrapartida: el icono no puede mostrar un contador de pendientes.
- **Drive:** se retiró la sección para reducir el alcance de la integración.
- **Marcas de visto y hecho en `localStorage`**, no en la base de datos del artifact: suficiente para un solo usuario en un solo navegador y sin configuración extra.
- **Interfaz en inglés**, documentación en español.
- **v2: sincronización diaria en vez de cada 5 minutos**, a petición tuya. El botón Sync all cubre el resto.
- **v2: la app hace las llamadas y el panel presenta los resultados.** Las credenciales introducidas en Settings se envían al código nativo; los secretos guardados no se devuelven al panel.
