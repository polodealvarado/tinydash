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

## Decisiones

- **La app abre el panel en vez de leer los datos ella misma.** Elegido para no tener que crear credenciales de Google Cloud ni otra app de Slack (que habría tenido que aprobar el administrador). Contrapartida: el icono no puede mostrar un contador de pendientes.
- **Drive:** se retiró la sección para reducir el alcance de la integración.
- **Marcas de visto y hecho en `localStorage`**, no en la base de datos del artifact: suficiente para un solo usuario en un solo navegador y sin configuración extra.
- **Interfaz en inglés**, documentación en español.
