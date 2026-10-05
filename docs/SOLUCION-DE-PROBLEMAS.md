# Solución de problemas (v2)

| Síntoma | Qué hacer |
|---|---|
| "Connect Google/Slack in Settings" | No hay credenciales. Sigue `docs/CONFIGURACION.md`. |
| "Google access expired or was revoked" | Settings → Google → Disconnect y vuelve a conectar. |
| Google dice `access_denied` o "app bloqueada" | Comprueba el cliente OAuth de tipo *Desktop app*, la audiencia de la pantalla de consentimiento y el acceso de tu cuenta; activa las APIs de Gmail y Calendar. |
| "Slack: missing_scope" / "invalid_auth" | El token tiene que ser el *User OAuth Token* (`xoxp-`) con `search:read`, no el de bot (`xoxb-`). |
| La sección de Slack sale vacía pero tienes mensajes | Comprueba los permisos del token y las consultas de `runSlack()`. No pegues el token en comandos que queden guardados en el historial de la terminal. |
| macOS pregunta por el llavero tras recompilar | Puede ocurrir con la firma ad hoc. Comprueba que quien solicita acceso es tu copia de Tinydash. |
| La página sale en blanco | Clic derecho dentro de la ventana → **Inspect Element** → consola. |
