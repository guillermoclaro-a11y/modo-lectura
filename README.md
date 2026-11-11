# Modo lectura

Widget para KDE Plasma 6 que te ayuda a leer sin caer en el agujero negro de YouTube.

Haces clic en el libro del panel, eliges cuánto tiempo vas a leer y listo: durante la sesión
**se bloquean YouTube y los sitios que elijas**, se **silencian las notificaciones** y
(opcionalmente) se **bloquea la pantalla**. Al terminar aparece un aviso y suena una alarma,
y todo vuelve a la normalidad solo.

*[English version](README.en.md)*

## Características

- Sesiones de 15, 25, 45 o 60 minutos, o la duración que quieras (1 a 240).
- Cuenta regresiva en el panel.
- Lista de sitios configurable, con atajos para YouTube, Instagram, TikTok, Facebook, X, Reddit, Netflix y Twitch.
- Bloquea en todos los navegadores (Firefox, Chrome, también en flatpak), porque actúa a nivel del sistema.
- **Nunca deja nada bloqueado por error**: si cierras la sesión o se apaga la computadora, los sitios se desbloquean solos.
- En español e inglés según el idioma del sistema.
- Accesible: se maneja con el teclado (Tab, Enter, Espacio), funciona con lector de pantalla (Orca),
  puede anunciar el tiempo restante y el aviso final no depende solo del sonido.

## Instalación

### Desde la KDE Store
1. Clic derecho en el panel → *Agregar widgets…* → *Obtener widgets nuevos…* → busca **Modo lectura**.
2. Agrégalo al panel, ábrelo y toca **Configurar ahora**. Se te va a pedir la contraseña de
   administrador una sola vez.

### Desde el código fuente (todas las cuentas del equipo)
```bash
git clone https://github.com/guillermoclaro-a11y/modo-lectura.git
cd modo-lectura
make check          # opcional: corre las pruebas
sudo make install
```
Después: clic derecho en el panel → *Agregar widgets…* → **Modo lectura**.

### Fedora (COPR)
```bash
sudo dnf copr enable guillermoclaro-a11y/modo-lectura
sudo dnf install modo-lectura
```

### Requisitos
Plasma 6, polkit, systemd, Python 3 con `python3-gobject`, `notify-send` y `paplay`
(vienen instalados en Fedora KDE, Kubuntu, KDE neon, openSUSE y Arch con Plasma).

## Uso desde la terminal
```bash
modo-lectura start 25                          # 25 minutos con los sitios configurados
modo-lectura start 45 --no-lock --no-sound     # sin bloquear pantalla ni alarma
modo-lectura start 30 --sites "instagram.com tiktok.com"
modo-lectura stop                              # terminar antes
modo-lectura status
```
Para la terminal, la lista de sitios se lee de `~/.config/modo-lectura/sites` (uno por línea);
si no existe, se bloquea YouTube.

## Cómo funciona

| Pieza | Qué hace |
|---|---|
| `contents/ui/` | El widget (QML). |
| `contents/code/modo-lectura` | Inicia y termina sesiones; temporizador con `systemd-run --user`. |
| `contents/code/do-not-disturb.py` | Mantiene el "No molestar" de Plasma mientras dura la sesión. |
| `contents/system/hosts-helper` | Único componente con permisos de root: agrega o quita un bloque marcado en `/etc/hosts`. |
| Política polkit | Permite bloquear sin contraseña solo al usuario de la sesión activa; desbloquear siempre está permitido. |
| `modo-lectura-unblock.service` | Al arrancar el equipo, se asegura de que no quede nada bloqueado. |

Seguridad: el ayudante valida la duración (1–240) y cada dominio. Solo modifica las líneas entre
`# >>> modo-lectura >>>` y `# <<< modo-lectura <<<`, y programa como root un desbloqueo de
respaldo 2 minutos después del final de la sesión.

Limitación: una pestaña que ya tenía el sitio abierto puede seguir funcionando
alrededor de un minuto, hasta que el navegador cierre la conexión. Las páginas nuevas ya no cargan.

## Desinstalar
```bash
sudo make uninstall          # instalado desde el código
sudo dnf remove modo-lectura # instalado desde COPR
```
Si lo instalaste desde la KDE Store:
`sudo bash ~/.local/share/plasma/plasmoids/org.guillermo.modolectura/contents/code/install-system.sh --uninstall`

## Traducir
```bash
make pot                                   # extrae los textos a po/template.pot
cp po/template.pot po/fr.po                # nuevo idioma (o: python3 tools/update-po.py po/es.po)
make check
```
No hace falta gettext: las herramientas de `tools/` son Python puro.

## Licencia
MIT
