#!/bin/bash
# Builds Grimoire.app from the SwiftPM-emitted executable + resource
# bundle. The result is a proper macOS app bundle with an Info.plist,
# bundle identifier, and code signature -- which is what
# UNUserNotificationCenter (highlight notifications) needs to function.
#
# Usage:
#   ./scripts/build-app.sh                  # debug build, ad-hoc sign
#   CONFIG=release ./scripts/build-app.sh   # release build, ad-hoc sign
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)" \
#     ./scripts/build-app.sh                # sign with your dev cert
#
# Output: build/Grimoire.app
#
# To run after building:
#   open build/Grimoire.app
#
# To install (drag into /Applications):
#   cp -R build/Grimoire.app /Applications/

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

CONFIG="${CONFIG:-debug}"
BUNDLE_ID="${BUNDLE_ID:-com.zedarius.Grimoire}"
APP_NAME="Grimoire"
OUTPUT_DIR="build"
APP_PATH="$OUTPUT_DIR/$APP_NAME.app"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"   # `-` = ad-hoc

# Version comes from git describe so it tracks releases automatically.
# Falls back to "0.0.0+sha" if no tags exist yet.
SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
if [ -n "$TAG" ]; then
    SHORT_VERSION="${TAG#v}"
else
    SHORT_VERSION="0.0.0"
fi
# CFBundleVersion must be monotonically increasing for App Store but
# for personal use any unique value works. Using the commit count.
BUNDLE_VERSION="$(git rev-list --count HEAD 2>/dev/null || echo "1")"

echo "==> Building Grimoire ($CONFIG)"
swift build -c "$CONFIG"

# Find the built artifact dir. Swift puts it at
# .build/<arch>-apple-macosx/<config>/, e.g.
# .build/arm64-apple-macosx/debug/Grimoire.
BUILD_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BINARY="$BUILD_DIR/Grimoire"
RESOURCE_BUNDLE="$BUILD_DIR/Grimoire_Grimoire.bundle"

if [ ! -x "$BINARY" ]; then
    echo "ERROR: Built binary not found at $BINARY" >&2
    exit 1
fi

echo "==> Assembling $APP_PATH"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy the binary.
cp "$BINARY" "$APP_PATH/Contents/MacOS/$APP_NAME"

# Copy the SwiftPM-generated resource bundle (game-icons, etc.) into
# the standard Contents/Resources/ location -- Bundle.module checks
# Bundle.main.resourceURL first, which resolves there. Also stamp a
# minimal Info.plist into the SPM bundle so codesign --deep accepts
# it (SPM emits a bare folder, no Info.plist, which trips codesign's
# "bundle format unrecognized" check).
if [ -e "$RESOURCE_BUNDLE" ]; then
    DEST_BUNDLE="$APP_PATH/Contents/Resources/$(basename "$RESOURCE_BUNDLE")"
    cp -R "$RESOURCE_BUNDLE" "$DEST_BUNDLE"
    cat > "$DEST_BUNDLE/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID.resources</string>
    <key>CFBundleName</key>
    <string>Grimoire_Grimoire</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
</dict>
</plist>
EOF
fi

# Generate Info.plist. Keys are the minimum set needed for a launchable
# macOS app + notification authorization to succeed.
cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$SHORT_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUNDLE_VERSION</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.games</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Danny Olefsky</string>
    <!-- Build provenance, embedded so we can read it back at runtime
         even when .git isn't reachable (i.e., the .app was moved out
         of the build tree). BuildInfo.swift prefers the embedded
         value over the .git walk-up. -->
    <key>GrimoireGitSHA</key>
    <string>$SHORT_SHA</string>
    <key>GrimoireBuildConfig</key>
    <string>$CONFIG</string>
</dict>
</plist>
EOF

# Code-sign. Ad-hoc by default; user can pass CODESIGN_IDENTITY for a
# real cert. Notification authorization works under ad-hoc signing for
# locally-launched apps.
#
# `--deep` recurses into the .app's contents, including the SPM
# resource bundle (Grimoire_Grimoire.bundle), so we don't need an
# explicit pre-sign of that. The SPM "bundle" is really just a
# directory of resources (no inner Info.plist) so signing it as a
# standalone bundle would fail anyway.
echo "==> Code-signing (identity: $CODESIGN_IDENTITY)"
codesign --force --deep --sign "$CODESIGN_IDENTITY" \
    --options runtime \
    --timestamp=none \
    "$APP_PATH"

echo "==> Verifying signature"
codesign --verify --verbose "$APP_PATH" 2>&1 | sed 's/^/    /'

echo ""
echo "Done. $APP_PATH ($SHORT_VERSION, build $BUNDLE_VERSION, $SHORT_SHA)"
echo "Run:     open $APP_PATH"
echo "Install: cp -R $APP_PATH /Applications/"
