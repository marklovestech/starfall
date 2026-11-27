#!/bin/bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(uname -s)" != Darwin ]]; then
    echo "Building Starfall.app requires macOS and Swift 6." >&2
    exit 1
fi
config="${CONFIGURATION:-release}"
swift build --package-path "$repo/macOS" --configuration "$config"
products="$(swift build --package-path "$repo/macOS" --configuration "$config" --show-bin-path)"

app="$repo/build/Starfall.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$products/Starfall" "$app/Contents/MacOS/Starfall"
cp "$repo/macOS/Info.plist" "$app/Contents/Info.plist"
cp "$repo"/orig1986/product-build/{RESOURCE.DAT,SCORFILE.DAT,STARFALL.PIC,VOLTAR.DAT} "$app/Contents/Resources/"
cp "$repo"/orig1986/{HELPFILE.DAT,HELPINDX.DAT} "$app/Contents/Resources/"
codesign --force --sign - "$app"
printf '%s\n' "$app"
