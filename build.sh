#!/bin/bash
set -e

echo "🔨 Kompiliere ClipboardManager..."
swift build -c release

APP="ClipboardManager.app"
BIN=".build/release/ClipboardManager"

echo "📦 Erstelle App-Bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/ClipboardManager"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClipboardManager</string>
    <key>CFBundleIdentifier</key>
    <string>local.misgin.clipboardmanager</string>
    <key>CFBundleName</key>
    <string>ClipboardManager</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>ClipboardManager benötigt Zugriffsrechte, um Text automatisch einzufügen.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo ""
echo "✅ Fertig! Starte mit:"
echo "   open ClipboardManager.app"
echo ""
echo "⚠️  Beim ersten Start: Systemeinstellungen → Datenschutz & Sicherheit"
echo "   → Bedienungshilfen → ClipboardManager aktivieren"
