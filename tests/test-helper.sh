#!/bin/bash
# Tests the privileged helper against a fake hosts file (no root needed).
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/bin" "$T/helper"
printf '#!/bin/sh\nexit 0\n' > "$T/bin/systemctl"; cp "$T/bin/systemctl" "$T/bin/systemd-run"; chmod +x "$T/bin/"*
sed -e "s#^HOSTS=.*#HOSTS=$T/hosts#" -e "s#^export PATH=.*#export PATH=$T/bin:/usr/bin#" \
    "$ROOT/package/contents/system/hosts-helper" > "$T/helper/block"
cp "$T/helper/block" "$T/helper/unblock"; chmod +x "$T/helper/"*
B="$T/helper/block"; U="$T/helper/unblock"
fails=0
ok()   { echo "  ok   $1"; }
bad()  { echo "  FAIL $1"; fails=$((fails+1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

printf '127.0.0.1 localhost\n::1 localhost\n' > "$T/hosts"; cp "$T/hosts" "$T/orig"

"$B" 25 youtube.com youtu.be
check "blocks a domain"                 'grep -qx "0.0.0.0 youtube.com" "$T/hosts"'
check "blocks IPv6 too"                 'grep -qx ":: youtube.com" "$T/hosts"'
check "adds the www. variant"           'grep -qx "0.0.0.0 www.youtube.com" "$T/hosts"'
"$B" 30 instagram.com
check "re-blocking does not duplicate"  '[ "$(grep -c "^# >>> modo-lectura" "$T/hosts")" = 1 ]'
check "re-blocking replaces the list"   '! grep -q youtube "$T/hosts" && grep -q instagram "$T/hosts"'
"$U"
check "unblock restores the file"       'cmp -s "$T/hosts" "$T/orig"'
"$U"
check "unblock is idempotent"           'cmp -s "$T/hosts" "$T/orig"'

printf '127.0.0.1 localhost' > "$T/hosts"
"$B" 08 example.com
check "handles a missing final newline" 'head -1 "$T/hosts" | grep -qx "127.0.0.1 localhost"'
check "accepts leading zeros (08)"      'grep -q example.com "$T/hosts"'
"$U"

for args in "0 a.com" "241 a.com" "abc a.com" "25" "25 localhost" "25 -rf" "25 a.com;rm" \
            "25 ../etc" "25 http://a.com" "25 A..com" "25 a.com extra\ninjected"; do
    # shellcheck disable=SC2086
    if "$B" $args 2>/dev/null; then bad "rejects: block $args"; else ok "rejects: block $args"; fi
done
if "$U" extra 2>/dev/null; then bad "rejects: unblock extra"; else ok "rejects: unblock extra"; fi

echo; (( fails == 0 )) && echo "helper: all tests passed" || { echo "helper: $fails failed"; exit 1; }
