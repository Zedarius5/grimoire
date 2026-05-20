#!/usr/bin/env bash
# Build Grimoire and launch it as a proper .app bundle (gets a dock icon, window focus).
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-debug}"
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
APP=".build/Grimoire.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Grimoire" "$APP/Contents/MacOS/Grimoire"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi

# Sign with the user's Apple Development / Developer ID certificate so macOS
# Keychain ACLs and TCC (file access) permissions stay stable across rebuilds.
# Without a real cert, every rebuilt binary looks like a new app to the OS and
# the user has to re-grant access on every launch. The env var lets you
# override the identity explicitly (use either the cert name or its SHA-1).
if [ -n "${GRIMOIRE_SIGN_IDENTITY:-}" ]; then
    SIGN_IDENTITY="$GRIMOIRE_SIGN_IDENTITY"
else
    SIGN_IDENTITY="$(security find-identity -v -p codesigning \
        | grep -E 'Apple Development|Apple Distribution|Developer ID Application' \
        | head -1 \
        | awk -F'"' '{print $2}')"
fi

if [ -n "$SIGN_IDENTITY" ]; then
    codesign --force --sign "$SIGN_IDENTITY" \
        --identifier com.zedarius.Grimoire \
        --timestamp=none \
        "$APP" 2>&1 | grep -v "replacing existing signature" || true
    echo "Signed with: $SIGN_IDENTITY"
else
    # No real cert available — fall back to ad-hoc signing. macOS will prompt
    # for Keychain / file access on every rebuild in this mode.
    codesign --force --sign - \
        --identifier com.zedarius.Grimoire \
        --timestamp=none \
        "$APP" 2>&1 | grep -v "replacing existing signature" || true
    echo "Ad-hoc signed (no developer cert found)"
fi

# Install the freshly-signed bundle into /Applications so the user always has a
# stable launch point in Spotlight / Launchpad / Dock. Falls back to ~/Applications
# if /Applications isn't writable (some hardened-runtime / managed Macs).
INSTALL_DIR="/Applications"
if [ ! -w "$INSTALL_DIR" ]; then
    INSTALL_DIR="$HOME/Applications"
    mkdir -p "$INSTALL_DIR"
fi
INSTALLED_APP="$INSTALL_DIR/Grimoire.app"

# Kill any running instance (built-tree or installed) so the rebuilt binary is
# what launches.
pkill -f "Grimoire.app/Contents/MacOS/Grimoire" 2>/dev/null || true
sleep 0.3

rm -rf "$INSTALLED_APP"
cp -R "$APP" "$INSTALLED_APP"
echo "Installed to: $INSTALLED_APP"

# Tell Finder/LaunchServices the icon changed so the new picture shows up
# without a logout. `touch` bumps the bundle mtime; killall Finder forces a
# refresh of any visible icon caches.
touch "$INSTALLED_APP"

open "$INSTALLED_APP"
