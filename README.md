# Tinydash

Lo que necesita tu atención hoy en un solo sitio, a un clic desde la barra de menús del Mac: agenda, tareas, correo sin leer y Slack. No depende de claude.ai.

## Instalar la app

```bash
xcode-select --install     # una vez, si falta swiftc
git clone https://github.com/polodealvarado/tinydash.git
cd tinydash/macos-app
./build.sh                 # compila, instala en /Applications y la abre
```

El resultado es **Tinydash.app**. Para compilar sin instalar ni abrir la app, usa `./build.sh --build-only`.

La primera vez, abre **Settings** en el panel y conecta Google y Slack siguiendo `docs/CONFIGURACION.md`.

Pulsa el lápiz de la barra para abrir el panel. **Sync all** sincroniza todo; además se sincroniza sola una vez al día. Clic derecho en el lápiz: Sync now, Open at login y Quit.

## Interfaz

La vista **Overview** reúne el día completo. Los contadores y las pestañas **Agenda**, **Tasks**, **Inbox** y **Slack** permiten ir directamente a cada sección. Incluye modo claro y oscuro según macOS.

## Compatibilidad con Your Nymiz

Tinydash es el nuevo nombre de Your Nymiz desde la versión 2.2. Se conservan el identificador `com.nymiz.yournymiz`, el elemento del llavero y la carpeta `~/Library/Application Support/YourNymiz/` para reutilizar las conexiones y tareas existentes.

## Estructura

```
tinydash/
├── CLAUDE.md                contexto para Claude Code (en inglés)
├── dashboard/index.html     el panel (va dentro de la app)
├── macos-app/               app de la barra (main.swift, Info.plist, build.sh)
├── assets/                  icono del lápiz (SVG)
└── docs/
    ├── ARQUITECTURA.md          cómo encaja todo y qué APIs se llaman
    ├── CONFIGURACION.md         credenciales de Google y Slack, datos y sincronización
    ├── SOLUCION-DE-PROBLEMAS.md errores habituales
    ├── HISTORIAL.md             versiones y decisiones tomadas
    └── ROADMAP.md               ideas pendientes
```
