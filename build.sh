#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP="StickyImage.app"

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/StickyImage "$APP/Contents/MacOS/StickyImage"
cp Resources/Info.plist       "$APP/Contents/Info.plist"

codesign --force --deep --sign - "$APP"

echo "Built $APP"
echo "Run:  open $APP"
