# Your Nymiz

Lo que necesita tu atención hoy en un solo sitio, a un clic desde la barra de menús del Mac: agenda, tareas, correo sin leer y Slack. No depende de claude.ai.

## Instalar la app

```bash
xcode-select --install     # una vez, si falta swiftc
cd macos-app
./build.sh                 # compila, instala en /Applications y la abre
```

La primera vez, abre **Settings** en el panel y conecta Google y Slack siguiendo `docs/CONFIGURACION.md`.

Pulsa el fantasma de la barra para abrir el panel. **Sync all** sincroniza todo; además se sincroniza sola una vez al día. Clic derecho en el fantasma: Sync now, Open at login y Quit.

## Estructura

```
your-nymiz/
├── CLAUDE.md                contexto para Claude Code (en inglés)
├── dashboard/index.html     el panel (va dentro de la app)
├── macos-app/               app de la barra (main.swift, Info.plist, build.sh)
├── assets/                  icono del fantasma (SVG) y vista previa
└── docs/
    ├── ARQUITECTURA.md          cómo encaja todo y qué APIs se llaman
    ├── CONFIGURACION.md         credenciales de Google y Slack, datos y sincronización
    ├── SOLUCION-DE-PROBLEMAS.md errores habituales
    ├── HISTORIAL.md             versiones y decisiones tomadas
    └── ROADMAP.md               ideas pendientes
```
