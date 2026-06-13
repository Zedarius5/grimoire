#!/bin/bash
# One-shot: build Grimoire, bundle it into a proper .app, code-sign
# (auto-detecting your Apple Development / Developer ID cert), install
# to /Applications, and launch.
#
# Default behavior is "do everything"; flag-style env vars let you
# opt out of pieces:
#
#   ./scripts/build-app.sh                       # debug, sign, install, launch
#   CONFIG=release ./scripts/build-app.sh        # release, sign, install, launch
#   INSTALL=0 LAUNCH=0 ./scripts/build-app.sh    # build + sign only, leave in build/
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)" \
#     ./scripts/build-app.sh                     # explicit cert override
#
# Output (always): build/Grimoire.app
# Output (when INSTALL=1): /Applications/Grimoire.app  (or ~/Applications)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

CONFIG="${CONFIG:-debug}"
BUNDLE_ID="${BUNDLE_ID:-com.zedarius.Grimoire}"
APP_NAME="Grimoire"
OUTPUT_DIR="build"
APP_PATH="$OUTPUT_DIR/$APP_NAME.app"
INSTALL="${INSTALL:-1}"
LAUNCH="${LAUNCH:-1}"

# Auto-detect a signing identity unless the caller pinned one. Prefers
# real certs (Apple Development / Apple Distribution / Developer ID
# Application) so Keychain ACLs + TCC permissions stay stable across
# rebuilds. Falls back to ad-hoc if no real cert is found -- in that
# case macOS will re-prompt for file/keychain access on every rebuild.
if [ -z "${CODESIGN_IDENTITY:-}" ]; then
    CODESIGN_IDENTITY="$(security find-identity -v -p codesigning \
        | grep -E 'Apple Development|Apple Distribution|Developer ID Application' \
        | head -1 \
        | awk -F'"' '{print $2}' \
        || true)"
    if [ -z "$CODESIGN_IDENTITY" ]; then
        CODESIGN_IDENTITY="-"
    fi
fi
SIGN_LABEL="$CODESIGN_IDENTITY"
[ "$CODESIGN_IDENTITY" = "-" ] && SIGN_LABEL="ad-hoc (no developer cert found)"

# Build provenance: short SHA + commit count for CFBundleVersion.
SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
SHORT_VERSION="${TAG#v}"
[ -z "$SHORT_VERSION" ] && SHORT_VERSION="0.0.0"
BUNDLE_VERSION="$(git rev-list --count HEAD 2>/dev/null || echo "1")"

echo "==> Building Grimoire ($CONFIG)"
swift build -c "$CONFIG"

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

cp "$BINARY" "$APP_PATH/Contents/MacOS/$APP_NAME"

# App icon (if present in repo Resources).
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$APP_PATH/Contents/Resources/AppIcon.icns"
fi

# SwiftPM resource bundle -> Contents/Resources/ (where
# Bundle.main.resourceURL -> Bundle.module resolves it). Stamp a
# minimal Info.plist inside so codesign --deep accepts the .bundle
# folder (SPM emits a bare directory without one).
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

# Top-level Info.plist. Generated fresh each build so version + SHA
# always reflect the current commit. Schema: minimum keys for a
# launchable Mac app + UNUserNotificationCenter authorization +
# AppIcon + readable build provenance for the title bar.
cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
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
    <!-- Deliberately NOT public.app-category.games: that category is
         what enrolls the app in macOS's Games app + "Now Playing"
         overlay + Game Mode. Grimoire is a MUD/text client, so we
         categorize it as a utility to stay out of that UI entirely. -->
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Danny Olefsky</string>
    <!-- Read by BuildInfo.swift to put the SHA in the window title
         bar even after the .app is moved out of the build tree. -->
    <key>GrimoireGitSHA</key>
    <string>$SHORT_SHA</string>
    <key>GrimoireBuildConfig</key>
    <string>$CONFIG</string>
</dict>
</plist>
EOF

echo "==> Code-signing ($SIGN_LABEL)"
codesign --force --deep --sign "$CODESIGN_IDENTITY" \
    --identifier "$BUNDLE_ID" \
    --options runtime \
    --timestamp=none \
    "$APP_PATH" 2>&1 | grep -v "replacing existing signature" || true

# Verify; fail loudly so we don't hand the user a broken bundle.
codesign --verify --verbose "$APP_PATH" 2>&1 | sed 's/^/    /'

echo "==> $APP_PATH built ($SHORT_VERSION, build $BUNDLE_VERSION, $SHORT_SHA)"

# --- Install + launch ---

if [ "$INSTALL" = "1" ]; then
    INSTALL_DIR="/Applications"
    if [ ! -w "$INSTALL_DIR" ]; then
        INSTALL_DIR="$HOME/Applications"
        mkdir -p "$INSTALL_DIR"
    fi
    INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"

    # Kill any running instance (built-tree or installed) so the
    # rebuilt binary is what launches.
    pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true
    sleep 0.3

    rm -rf "$INSTALLED_APP"
    cp -R "$APP_PATH" "$INSTALLED_APP"
    # Bump mtime so LaunchServices invalidates any cached icon.
    touch "$INSTALLED_APP"
    echo "==> Installed to $INSTALLED_APP"

    if [ "$LAUNCH" = "1" ]; then
        echo "==> Launching"
        open "$INSTALLED_APP"
    fi
elif [ "$LAUNCH" = "1" ]; then
    # Skipping install but still launching: run from build/.
    pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true
    sleep 0.3
    echo "==> Launching $APP_PATH"
    open "$APP_PATH"
fi
