#!/bin/bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
emulator="${DOSBOX:-dosbox-x}"
if ! command -v "$emulator" >/dev/null; then
    echo "Install DOSBox-X or set DOSBOX to a compatible DOSBox executable." >&2
    exit 1
fi

work="${STARFALL_DOS_DIR:-$repo/build/dos}"
game="$work/game"
overlays="$work/overlays"
mkdir -p "$game" "$overlays"
copy_missing() {
    local destination="$1" source
    shift
    for source in "$@"; do
        if [[ ! -e "$destination/${source##*/}" ]]; then
            cp "$source" "$destination/"
        fi
    done
}
copy_missing "$game" "$repo"/orig1986/product-build/* "$repo"/orig1986/{HELPFILE.DAT,HELPINDX.DAT,INSTALL.COM}
copy_missing "$overlays" "$repo"/orig1986/product-build/PLAYGAME.0*
game="$(cd "$game" && pwd)"
overlays="$(cd "$overlays" && pwd)"
flags=(-machine cga)
if [[ "${emulator##*/}" == dosbox-x ]]; then
    flags+=(-defaultconf -fastlaunch -nomenu)
fi
"$emulator" "${flags[@]}" -c "mount c \"$game\"" -c "mount d \"$overlays\"" -c 'c:' -c 'starfall'
