"""Keep Plasma's "Do not disturb" on for N seconds.

The org.freedesktop.Notifications inhibition lasts as long as this process
stays on the bus, so it is released automatically when it exits or is stopped.
"""
import sys
import time

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

seconds = int(sys.argv[1]) if len(sys.argv) > 1 else 1500
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
bus.call_sync(
    "org.freedesktop.Notifications", "/org/freedesktop/Notifications",
    "org.freedesktop.Notifications", "Inhibit",
    GLib.Variant("(ssa{sv})", ("modo-lectura", "Reading session", {})),
    GLib.VariantType("(u)"), Gio.DBusCallFlags.NONE, -1, None,
)
time.sleep(seconds)
