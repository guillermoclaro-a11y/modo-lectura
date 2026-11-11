#!/usr/bin/env python3
"""Merge po/template.pot into an existing po/<lang>.po (like msgmerge).

Keeps existing translations, adds new strings untranslated, drops obsolete ones.
Usage: python3 tools/update-po.py po/es.po
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
po_path = pathlib.Path(sys.argv[1])
pot = (ROOT / "po/template.pot").read_text(encoding="utf-8")
po = po_path.read_text(encoding="utf-8")

def key(block):
    ctx = re.search(r'^msgctxt "(.*)"$', block, re.M)
    mid = re.search(r'^msgid "(.*)"$', block, re.M)
    return (ctx.group(1) if ctx else None, mid.group(1) if mid else None)

def strs(block):
    return re.findall(r'^(msgstr(?:\[\d\])?) "(.*)"$', block, re.M)

blocks = po.split("\n\n")
header, old = blocks[0], {key(b): dict(strs(b)) for b in blocks[1:] if b.strip()}
out, new = [header], []
for block in pot.split("\n\n")[1:]:
    if not block.strip():
        continue
    tr = old.get(key(block), {})
    if not tr or not any(tr.values()):
        new.append(key(block)[1])
    for name, _ in strs(block):
        block = re.sub(rf'^{re.escape(name)} ""$', lambda m: f'{name} "{tr.get(name, "")}"', block, flags=re.M)
    out.append(block)
po_path.write_text("\n\n".join(out).rstrip("\n") + "\n\n", encoding="utf-8")
print(f"{po_path}: {len(new)} untranslated", *new, sep="\n  ")
