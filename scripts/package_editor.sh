#!/bin/bash
set -e

APP_NAME="AstorkaEditor"
APP_BUNDLE="${APP_NAME}.app"

echo "🔨 [Astorka Editor] Starting release build..."
swift build -c release --product astorka-editor

echo "📦 [Astorka Editor] Creating macOS .app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp ".build/release/astorka-editor" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cat <<EOF > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.astorka.editor</string>
    <key>CFBundleName</key>
    <string>Astorka Editor</string>
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

echo "✅ [Astorka Editor] Ready! Bundle: ${APP_BUNDLE}"
echo "👉 To launch: open \"${APP_BUNDLE}\""
