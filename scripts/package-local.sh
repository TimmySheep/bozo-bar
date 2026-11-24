#!/bin/bash
# Build an isolated package; never modify the installed app here.
set -euo pipefail
cd "$(dirname "$0")/.."
bash tests/check-panel.sh
mkdir -p dist
stage=$(mktemp -d "$PWD/dist/local.XXXXXX")
src=Sources/BozoBar
xcrun swiftc -parse-as-library "$src/Models.swift" "$src/BmapCodec.swift" "$src/BmapProtocol.swift" tests/ModeContract.swift -o "$stage/mode-check"
"$stage/mode-check"
xcrun swiftc -parse-as-library "$src/MenuPopoverLayout.swift" tests/PopoverSizingContract.swift -o "$stage/popover-size-check"
"$stage/popover-size-check"
# The default Swift Build engine can stamp the deployment target as the SDK.
# Use the verified linker path; AppKit uses the linked SDK to select modern styling.
local_build=(swift build --build-system native --scratch-path "$PWD/.build/local-native" -c release)
"${local_build[@]}"
bin=$("${local_build[@]}" --show-bin-path)
sdk_expected=$(xcrun --sdk macosx --show-sdk-version)
meta=$(xcrun vtool -show-build "$bin/BozoBar")
sdk_linked=$(awk '$1 == "sdk" { print $2 }' <<< "$meta")
printf '%s\n' "$meta"
if [ "$sdk_linked" != "$sdk_expected" ]; then
    printf 'Unexpected linked macOS SDK: %s (expected %s)\n' "$sdk_linked" "$sdk_expected" >&2
    exit 1
fi
app="$stage/BozoBar.app"
res="$app/Contents/Resources"
mkdir -p "$app/Contents/MacOS" "$res" "$stage/icon/AppIcon.iconset" "$stage/icon/modern"
cp "$bin/BozoBar" "$app/Contents/MacOS/BozoBar"
for bundle in "$bin"/*.bundle; do [ ! -d "$bundle" ] || ditto "$bundle" "$res/$(basename "$bundle")"; done
cp Info.plist "$app/Contents/Info.plist"
p="$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :NSPrincipalClass string NSApplication' "$p"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon.icns' "$p"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconName string AppIcon' "$p"
for n in 16 32 128 256 512; do
  sips -z "$n" "$n" design/generated/Legacy.png --out "$stage/icon/AppIcon.iconset/icon_${n}x${n}.png" >/dev/null
  twice=$((n*2))
  sips -z "$twice" "$twice" design/generated/Legacy.png --out "$stage/icon/AppIcon.iconset/icon_${n}x${n}@2x.png" >/dev/null
done
iconutil -c icns "$stage/icon/AppIcon.iconset" -o "$res/AppIcon.icns"
xcrun actool design/AppIcon.icon --compile "$stage/icon/modern" --platform macosx --minimum-deployment-target 26.0 --app-icon AppIcon --output-partial-info-plist "$stage/icon/partial.plist"
cp "$stage/icon/modern/Assets.car" "$res/Assets.car"
xcrun assetutil --info "$res/Assets.car" > "$stage/icon/asset-info.json"
python3 - "$stage/icon/asset-info.json" <<'PY'
import json, sys
items = json.load(open(sys.argv[1]))
matching = [d for d in items if d.get('Name') == 'AppIcon' or 'Headphones' in str(d.get('Name',''))]
assert matching, items
for d in matching:
    print({k: d[k] for k in ('Name', 'AssetType', 'LayerCount', 'SizeOnDisk', 'PixelWidth', 'PixelHeight') if k in d})
assert any(d.get('LayerCount', 0) >= 2 for d in matching), matching
PY
# Set CODESIGN_IDENTITY to a Developer ID Application identity to sign for distribution;
# with it unset the bundle is signed ad-hoc, which is fine for local use only.
if [ -n "${CODESIGN_IDENTITY:-}" ] && \
   codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" \
            --entitlements BozoBar.entitlements "$app"; then
  printf 'Signed with: %s\n' "$CODESIGN_IDENTITY"
else
  printf 'Signing ad-hoc; set CODESIGN_IDENTITY to sign with a Developer ID.\n'
  codesign --force --sign - --entitlements BozoBar.entitlements "$app"
fi
plutil -lint "$p"
codesign --verify --strict "$app"
stat -f '%z bytes %N' "$res/AppIcon.icns" "$res/Assets.car"
printf 'STAGED_APP=%s\n' "$app"
