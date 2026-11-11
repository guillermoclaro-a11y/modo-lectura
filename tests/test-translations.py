"""Checks that every translatable string in the QML has a Spanish translation."""
import gettext
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parent.parent
pot = subprocess.run([sys.executable, "-I", str(root / "tools/extract-messages.py")],
                     capture_output=True, text=True, check=True).stdout
mo = root / "build/locale/es/LC_MESSAGES/plasma_applet_io.github.guillermoclaro.modolectura.mo"
t = gettext.GNUTranslations(mo.open("rb"))
missing = []
for block in pot.split("\n\n")[1:]:
    m = re.search(r'^msgid "(.*)"$', block, re.M)
    if not m:
        continue
    msgid = m.group(1).encode().decode("unicode_escape").encode("latin-1").decode("utf-8")
    ctx = re.search(r'^msgctxt "(.*)"$', block, re.M)
    if "msgid_plural" in block:
        plural = re.search(r'^msgid_plural "(.*)"$', block, re.M).group(1)
        found = t.ngettext(msgid, plural, 2) != plural or t.ngettext(msgid, plural, 1) != msgid
    elif ctx:
        found = t.pgettext(ctx.group(1), msgid) != msgid or msgid == "%1 min" or msgid == "min"
    else:
        found = t.gettext(msgid) != msgid or msgid == "General"
    if not found:
        missing.append(msgid)
if missing:
    print("translations: missing in es.po:", *missing, sep="\n  ")
    sys.exit(1)
print("translations: all strings translated")
