# Reading Mode (Modo lectura)

A KDE Plasma 6 widget that helps you read without falling down the YouTube rabbit hole.

Click the book in your panel, pick how long you will read, and that's it: during the session
**YouTube and any sites you choose are blocked**, **notifications are muted** and the screen
is (optionally) **locked**. When time is up you get a notification and an alarm, and
everything goes back to normal on its own.

*[Versión en español](README.md)*

## Features

- 15, 25, 45 or 60-minute sessions, or any length from 1 to 240 minutes.
- Countdown right in the panel.
- Configurable site list with one-click presets (YouTube, Instagram, TikTok, Facebook, X, Reddit, Netflix, Twitch).
- Works in every browser (Firefox, Chrome, Flatpak too), because blocking happens system-wide.
- **Never leaves anything blocked by mistake**: sites are unblocked even after a logout or a reboot.
- English and Spanish, following the system language.
- Accessible: fully keyboard operable (Tab, Enter, Space), screen-reader friendly (Orca), optional
  spoken progress announcements, and the end-of-session signal does not rely on sound alone.

## Installation

### KDE Store
1. Right-click the panel → *Add Widgets…* → *Get New Widgets…* → search for **Reading Mode**.
2. Add it, open it and press **Set up now**. Your administrator password is requested once.

### From source (all accounts on the computer)
```bash
git clone https://github.com/GITHUB_USER/modo-lectura.git
cd modo-lectura
make check          # optional: run the tests
sudo make install
```

### Fedora (COPR)
```bash
sudo dnf copr enable GITHUB_USER/modo-lectura
sudo dnf install modo-lectura
```

### Requirements
Plasma 6, polkit, systemd, Python 3 with `python3-gobject`, `notify-send` and `paplay`.

## Command line
```bash
modo-lectura start 25
modo-lectura start 45 --no-lock --no-sound
modo-lectura start 30 --sites "instagram.com tiktok.com"
modo-lectura stop
modo-lectura status
```

## How it works
The only privileged part is `contents/system/hosts-helper`, run through polkit. It validates its
input and only ever edits a marked block in `/etc/hosts`. The active session user can block without
a password; unblocking is always allowed. A root-side failsafe timer and a boot-time service make
sure nothing stays blocked.

## Uninstall
`sudo make uninstall`, or `sudo dnf remove modo-lectura`.

## License
MIT
