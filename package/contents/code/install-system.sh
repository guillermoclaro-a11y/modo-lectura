#!/bin/bash
# Installs the privileged part of Modo lectura (helpers, polkit policy and a
# boot-time safety service).  Run as root:
#   sudo bash install-system.sh            install
#   sudo bash install-system.sh --uninstall
# Packagers can set DESTDIR, LIBEXECDIR, POLKITDIR and UNITDIR.
set -euo pipefail

SRC=$(cd "$(dirname "$(readlink -f "$0")")/../system" && pwd)
DESTDIR=${DESTDIR:-}
LIBEXECDIR=${LIBEXECDIR:-/usr/local/libexec/modo-lectura}
POLKITDIR=${POLKITDIR:-/usr/share/polkit-1/actions}   # polkit only reads this one
UNITDIR=${UNITDIR:-/etc/systemd/system}
POLICY=io.github.guillermoclaro.modolectura.policy
UNIT=modo-lectura-unblock.service

live() { [[ -z $DESTDIR ]]; }
if live && (( EUID != 0 )); then echo "Run as root (sudo or pkexec)." >&2; exit 1; fi

remove_legacy() {
    # Before 1.1.1 the widget ID was org.guillermo.modolectura.
    rm -f "$POLKITDIR/org.guillermo.modolectura.policy"
    # Version 1.0 used a sudo rule and a single helper; replace them.
    if grep -qs 'modo-lectura-hosts' /etc/sudoers.d/modo-lectura; then rm -f /etc/sudoers.d/modo-lectura; fi
    if [[ -x /usr/local/libexec/modo-lectura-hosts ]]; then
        /usr/local/libexec/modo-lectura-hosts unblock 2>/dev/null || true
        rm -f /usr/local/libexec/modo-lectura-hosts
    fi
}

if [[ ${1:-} == --uninstall ]]; then
    if live; then
        [[ -x $LIBEXECDIR/unblock ]] && "$LIBEXECDIR/unblock" || true
        systemctl disable "$UNIT" 2>/dev/null || true
    fi
    rm -f "$DESTDIR$LIBEXECDIR/block" "$DESTDIR$LIBEXECDIR/unblock" \
          "$DESTDIR$POLKITDIR/$POLICY" "$DESTDIR$UNITDIR/$UNIT"
    rmdir "$DESTDIR$LIBEXECDIR" 2>/dev/null || true
    if live; then remove_legacy; systemctl daemon-reload; fi
    echo "Modo lectura: system part removed."
    exit 0
fi

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
sed "s#@LIBEXECDIR@#$LIBEXECDIR#g" "$SRC/$POLICY.in" > "$tmp/$POLICY"
sed "s#@LIBEXECDIR@#$LIBEXECDIR#g" "$SRC/$UNIT.in"   > "$tmp/$UNIT"

install -Dm0755 "$SRC/hosts-helper" "$DESTDIR$LIBEXECDIR/block"
install -Dm0755 "$SRC/hosts-helper" "$DESTDIR$LIBEXECDIR/unblock"
install -Dm0644 "$tmp/$POLICY" "$DESTDIR$POLKITDIR/$POLICY"
install -Dm0644 "$tmp/$UNIT"   "$DESTDIR$UNITDIR/$UNIT"

if live; then
    remove_legacy
    restorecon -R "$LIBEXECDIR" "$POLKITDIR/$POLICY" "$UNITDIR/$UNIT" 2>/dev/null || true
    systemctl daemon-reload
    systemctl enable "$UNIT" >/dev/null 2>&1 || true
fi
echo "Modo lectura: system part installed."
