#!/usr/bin/env python3
"""Compile a .po file into a GNU .mo file (contexts and plurals supported).

A small replacement for msgfmt.  Usage: build-mo.py input.po output.mo
"""
import ast
import pathlib
import struct
import sys


def parse_po(text):
    messages, cur, last = {}, {}, None

    def flush():
        if "msgid" in cur:
            msgid = cur["msgid"]
            if "msgid_plural" in cur:
                msgid += "\0" + cur["msgid_plural"]
                strs = [cur.get(f"msgstr[{i}]", "") for i in range(10) if f"msgstr[{i}]" in cur]
                msgstr = "\0".join(strs)
            else:
                msgstr = cur.get("msgstr", "")
            if "msgctxt" in cur:
                msgid = cur["msgctxt"] + "\x04" + msgid
            fuzzy = cur.get("fuzzy", False)
            if (msgstr.replace("\0", "") or msgid == "") and not fuzzy:
                messages[msgid] = msgstr
        cur.clear()

    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            flush(); last = None
            continue
        if line.startswith("#,") and "fuzzy" in line:
            cur["fuzzy"] = True
            continue
        if line.startswith("#"):
            continue
        if line.startswith('"'):
            cur[last] += ast.literal_eval(line)
            continue
        key, _, value = line.partition(" ")
        if key == "msgctxt" or (key == "msgid" and "msgid" in cur):
            flush()
        cur[key] = ast.literal_eval(value)
        last = key
    flush()
    return messages


def write_mo(messages, path):
    keys = sorted(messages)
    ids = b"".join(k.encode() + b"\0" for k in keys)
    strs = b"".join(messages[k].encode() + b"\0" for k in keys)
    n = len(keys)
    header = 7 * 4
    ids_start = header + 16 * n
    strs_start = ids_start + len(ids)
    otable, ttable, o, t = [], [], 0, 0
    for k in keys:
        kb, vb = k.encode(), messages[k].encode()
        otable += [len(kb), ids_start + o]; o += len(kb) + 1
        ttable += [len(vb), strs_start + t]; t += len(vb) + 1
    data = struct.pack("Iiiiiii", 0x950412DE, 0, n, header, header + 8 * n, 0, 0)
    data += struct.pack(f"{2 * n}i", *otable) + struct.pack(f"{2 * n}i", *ttable) + ids + strs
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(path).write_bytes(data)


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    write_mo(parse_po(pathlib.Path(src).read_text(encoding="utf-8")), dst)
