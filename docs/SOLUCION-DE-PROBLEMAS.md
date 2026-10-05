# Solución de problemas (v2)

| Síntoma | Qué hacer |
|---|---|
| "Connect Google/Slack in Settings" | No hay credenciales. Sigue `docs/CONFIGURACION.md`. |
| "Google access expired or was revoked" | Settings → Google → Disconnect y vuelve a conectar. |
| Google dice `access_denied` o "app bloqueada" | El cliente OAuth tiene que ser de tipo *Desktop app* y la pantalla de consentimiento *Interna*, con las APIs de Gmail y Calendar activadas. |
| "Slack: missing_scope" / "invalid_auth" | El token tiene que ser el *User OAuth Token* (`xoxp-`) con `search:read`, no el de bot (`xoxb-`). |
| La sección de Slack sale vacía pero tienes mensajes | Prueba la consulta en Slack: `curl -H "Authorization: Bearer xoxp-…" "https://slack.com/api/search.messages?query=to:<@TU_ID>%20after:AAAA-MM-DD"`. Si no devuelve nada, ajusta las consultas en `runSlack()`. |
| macOS pregunta por el llavero tras recompilar | Es normal con la firma ad hoc: **Permitir siempre**. |
| La página sale en blanco | Clic derecho dentro de la ventana → **Inspect Element** → consola. |
