#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CONFIGURATION=release

swift build --package-path "$ROOT_DIR" --configuration "$CONFIGURATION" --product Suohai

BIN_DIR=$(swift build --package-path "$ROOT_DIR" --configuration "$CONFIGURATION" --show-bin-path)

RESOURCE_BUNDLE="$BIN_DIR/Suohai_Suohai.bundle"
APP_BUNDLE="$ROOT_DIR/.build/Suohai.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_RESOURCES="$APP_CONTENTS/Resources"

if [ ! -d "$RESOURCE_BUNDLE" ]; then
    printf 'SwiftPM resource bundle was not found: %s\n' "$RESOURCE_BUNDLE" >&2
    exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_CONTENTS/MacOS" "$APP_RESOURCES/Suohai_Suohai.bundle" "$APP_RESOURCES/licenses"
cp "$BIN_DIR/Suohai" "$APP_CONTENTS/MacOS/Suohai"
cp "$ROOT_DIR/assets/plist/Info.plist" "$APP_CONTENTS/Info.plist"
cp "$ROOT_DIR/assets/icons/icon.icns" "$APP_RESOURCES/icon.icns"
cp "$ROOT_DIR/LICENSE.txt" "$APP_RESOURCES/LICENSE.txt"
cp "$ROOT_DIR/licenses/original-mit.txt" "$APP_RESOURCES/licenses/original-mit.txt"
cp -R "$RESOURCE_BUNDLE/." "$APP_RESOURCES/Suohai_Suohai.bundle/"

if [ -f "$RESOURCE_BUNDLE/Contents/Resources/Assets.car" ]; then
    cp "$RESOURCE_BUNDLE/Contents/Resources/Assets.car" "$APP_RESOURCES/Assets.car"
fi

printf 'Created %s\n' "$APP_BUNDLE"
