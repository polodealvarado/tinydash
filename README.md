# Your Nymiz

Lo que necesita tu atención hoy (agenda, correo sin leer y Slack) en un solo sitio, a un clic desde la barra de menús del Mac.

- **Panel:** https://example.com/dashboard (código: `dashboard/your-nymiz.html`)
- **App de la barra de menús:** `macos-app/`

## Instalar la app

```bash
xcode-select --install     # una vez, si falta swiftc
cd macos-app
./build.sh                 # compila, instala en /Applications y la abre
```

Pulsa el fantasma de la barra para abrir el panel. Clic derecho: Refresh, Open in browser, Diagnostics…, Open at login y Quit.

## Estructura

```
your-nymiz/
├── CLAUDE.md                  contexto para Claude Code (en inglés)
├── dashboard/your-nymiz.html  el panel publicado en claude.ai
├── macos-app/                 app de la barra (main.swift, Info.plist, build.sh)
├── assets/                    icono del fantasma (SVG) y vista previa
└── docs/
    ├── ARQUITECTURA.md              cómo encaja todo, datos y formatos
    ├── CONECTORES-Y-PUBLICACION.md  conectores, manifiesto y cómo publicar cambios
    ├── SOLUCION-DE-PROBLEMAS.md     panel en blanco, login, errores, git
    ├── HISTORIAL.md                 versiones y decisiones tomadas
    └── ROADMAP.md                   ideas pendientes
```

## Trabajar con Claude Code

```bash
cd ~/Documents/your-nymiz && claude
```

Claude Code puede editar el panel y la app. Para que los cambios del panel se vean en claude.ai hay que republicarlo desde claude.ai o Cowork (ver `docs/CONECTORES-Y-PUBLICACION.md`).
