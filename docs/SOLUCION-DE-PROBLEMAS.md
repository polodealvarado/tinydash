# Solución de problemas

## La ventana del fantasma sale en blanco

1. Espera unos segundos: debería verse un indicador de carga o un mensaje.
2. Clic derecho en el fantasma → **Diagnostics…** → **Copy**, y pega el texto a Claude.
3. Qué significa lo más habitual:
   - `URL: https://accounts.google.com/gsi/transform` y la página vacía: era el fallo del inicio de sesión con Google de la v1.1. Está corregido en la v1.2; recompila con `./build.sh`.
   - `URL: https://claude.ai/login`: no has iniciado sesión todavía. Hazlo en la ventana.
   - `Last error: NSURLErrorDomain -1009`: sin conexión a internet.

## Google dice "Este navegador o esta aplicación pueden no ser seguros"

Google a veces bloquea su inicio de sesión dentro de apps. Entra en claude.ai con tu **email** (te llega un código). La sesión se queda guardada igual.

## Una sección del panel muestra un error

| Mensaje | Qué hacer |
|---|---|
| "…is connected without read access" | Reconecta ese conector en Ajustes → Conectores y acepta todos los permisos. |
| "Your … session expired" | Reconecta el conector. |
| "Add … in Settings → Connectors" | El conector no está conectado en tu cuenta. |
| "…isn't allowed for this page. Reload to choose again." | Rechazaste el permiso de ese conector para el panel. Recarga y acéptalo. |
| "…isn't responding right now" | Fallo temporal; se reintenta en la siguiente actualización. |

## La sección de Slack sale vacía aunque tienes mensajes

La búsqueda de Slack devuelve texto con un formato concreto que el panel trocea (ver `docs/ARQUITECTURA.md`). Si Slack cambia ese formato, el trozado falla. Pide a Claude que haga una búsqueda real con el conector de Slack, compare el formato y ajuste `normSlack()`.

## Aparecen boletines en "Unread email"

Los filtros de categorías dependen de la configuración de Gmail. Se pueden excluir remitentes concretos en la consulta.

## Las marcas de "visto" no aparecen en otro dispositivo

Se guardan solo en el navegador donde las marcaste (`localStorage`). Para sincronizarlas haría falta la base de datos del artifact (ver `docs/ROADMAP.md`).

## Git se queja de un `.lock`

Al crear el repositorio desde Cowork no se podían borrar archivos y quedaron bloqueos de git. Se movieron a `.git/leftovers/`, y hay unos `tmp_obj_*` en `.git/objects` que git limpia solo. Puedes borrar `.git/leftovers/` cuando quieras. Si git dice que existe `index.lock` o `HEAD.lock`, bórralo:

```bash
rm -f .git/index.lock .git/HEAD.lock
```
