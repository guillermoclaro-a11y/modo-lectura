# Ficha para la KDE Store (store.kde.org)

Copiar cada campo en el formulario "Add Product".

## Campos

- **Category:** Plasma 6 Extensions → Plasma 6 Applets
- **Product name:** Modo lectura (Reading mode)
- **License:** MIT
- **Version:** 1.1.1
- **Link to source / Homepage:** https://github.com/guillermoclaro-a11y/modo-lectura
- **File:** `dist/modo-lectura-1.1.1.plasmoid`
- **Tags:** reading, focus, productivity, blocker, youtube, timer, accessibility

## Summary (una línea)

Read without distractions: blocks YouTube and other sites, mutes notifications and times your reading session.

## Description

Modo lectura (Reading mode) helps you get back to reading books without falling into YouTube.

Click the book in the panel, choose how long you will read, and that's it. During the session:
- YouTube and the sites you choose are blocked in every browser (Firefox, Chrome, Flatpak too)
- notifications are muted ("Do not disturb")
- the screen can be locked, so you put the computer down
- the time left is shown in the panel

When the time is up you get a notice and an alarm, and everything goes back to normal by itself.

**Nothing stays blocked by mistake:** if you log out or the computer turns off mid-session, the sites are unblocked automatically.

**Features**
- 15, 25, 45 or 60 minute sessions, or any length from 1 to 240 minutes
- Configurable site list, with shortcuts for YouTube, Instagram, TikTok, Facebook, X, Reddit, Netflix and Twitch
- Accessible: full keyboard use, works with the Orca screen reader, can announce the time left
- English and Spanish

**First use:** blocking sites needs a small one-time system setup. Open the widget and press "Set up now"; your administrator password is asked once (polkit). To remove it: see the README.

---

Modo lectura te ayuda a volver a leer libros sin caer en YouTube. Elegís cuánto vas a leer y durante la sesión se bloquean los sitios que elijas, se silencian las notificaciones y, si querés, se bloquea la pantalla. Al terminar suena una alarma y todo vuelve a la normalidad solo. En español e inglés.

## Changelog (1.1.1)

- The popup no longer falls under the panel.
- New widget ID: io.github.guillermoclaro.modolectura (if you had 1.1.0, remove it from the panel and add it again).
