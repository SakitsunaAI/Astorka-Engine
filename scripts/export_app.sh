#!/bin/bash
set -e

# Astorka Engine macOS .app Exporter
# Usage: ./scripts/export_app.sh [GameName] [ProjectJSONPath]

GAME_NAME="${1:-AstorkaGame}"
PROJECT_JSON="${2:-}"
APP_BUNDLE="${GAME_NAME}.app"

echo "🔨 [Astorka Engine] Starting release build for: ${GAME_NAME}..."
swift build -c release

echo "📦 [Astorka Engine] Creating macOS .app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp ".build/release/astorka-player" "${APP_BUNDLE}/Contents/MacOS/${GAME_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${GAME_NAME}"

# Embed game data if provided
if [ -n "$PROJECT_JSON" ] && [ -f "$PROJECT_JSON" ]; then
    echo "📄 [Astorka Engine] Embedding game data: ${PROJECT_JSON} -> Contents/Resources/game.json"
    cp "$PROJECT_JSON" "${APP_BUNDLE}/Contents/Resources/game.json"
fi

# Generate Info.plist
cat <<EOF > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${GAME_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.astorka.${GAME_NAME}</string>
    <key>CFBundleName</key>
    <string>${GAME_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Clean Gatekeeper attributes and ad-hoc codesign for macOS Sequoia/Sonoma
xattr -c "${APP_BUNDLE}" 2>/dev/null || true
codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null || true

echo "✅ [Astorka Engine] Completed successfully! Bundle: ${APP_BUNDLE}"
echo "👉 Double-click or run 'open \"${APP_BUNDLE}\"' to launch your game."
