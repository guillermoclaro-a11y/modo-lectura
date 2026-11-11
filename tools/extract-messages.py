#!/usr/bin/env python3
"""Extract i18n()/i18nc()/i18np() strings from the QML files into a .pot.

A small replacement for xgettext, so translators need nothing but Python.
Usage: python3 tools/extract-messages.py > po/template.pot
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
STR = r'"((?:[^"\\]|\\.)*)"'
PATTERNS = [
    ("i18n", re.compile(r'\bi18n\(\s*' + STR)),
    ("i18nc", re.compile(r'\bi18nc\(\s*' + STR + r'\s*,\s*' + STR)),
    ("i18np", re.compile(r'\bi18np\(\s*' + STR + r'\s*,\s*' + STR)),
]

entries = {}  # (ctx, msgid) -> (plural, [refs])
for qml in sorted((ROOT / "package").rglob("*.qml")):
    rel = qml.relative_to(ROOT)
    for lineno, line in enumerate(qml.read_text().splitlines(), 1):
        for kind, rx in PATTERNS:
            for m in rx.finditer(line):
                if kind == "i18n":
                    key, plural = (None, m.group(1)), None
                elif kind == "i18nc":
                    key, plural = (m.group(1), m.group(2)), None
                else:
                    key, plural = (None, m.group(1)), m.group(2)
                entries.setdefault(key, [plural, []])[1].append(f"{rel}:{lineno}")

out = sys.stdout
out.write('msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n\n')
for (ctx, msgid), (plural, refs) in entries.items():
    out.write("#: " + " ".join(refs) + "\n")
    if ctx:
        out.write(f'msgctxt "{ctx}"\n')
    out.write(f'msgid "{msgid}"\n')
    if plural:
        out.write(f'msgid_plural "{plural}"\nmsgstr[0] ""\nmsgstr[1] ""\n\n')
    else:
        out.write('msgstr ""\n\n')
