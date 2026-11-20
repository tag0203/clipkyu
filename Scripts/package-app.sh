#!/usr/bin/env bash
# Build a menu-bar .app. Ad-hoc signed so Accessibility can stick to the bundle id.
# No entitlements file: the app is unsandboxed and has no network client or server entitlement.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

swift build -c release --product Clipkyu
bin_dir="$(swift build -c release --product Clipkyu --show-bin-path)"
app="$root/dist/Clipkyu.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin_dir/Clipkyu" "$app/Contents/MacOS/Clipkyu"
cp "$root/App/Info.plist" "$app/Contents/Info.plist"
chmod 755 "$app/Contents/MacOS/Clipkyu"
codesign --force --sign - "$app"

echo "Built $app"
