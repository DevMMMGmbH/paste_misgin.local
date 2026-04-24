#!/bin/bash
set -e

echo "🔨 Kompiliere ClipFlow..."
swift build -c release

APP="ClipFlow.app"
BIN=".build/release/ClipFlow"

echo "📦 Erstelle App-Bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/ClipFlow"

# Icon ins Bundle kopieren
ICON_SRC="Sources/ClipboardManager/Resources/AppIcon.icns"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$APP/Contents/Resources/AppIcon.icns"
    echo "🖼  AppIcon.icns eingebunden"
fi

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClipFlow</string>
    <key>CFBundleIdentifier</key>
    <string>local.misgin.clipflow</string>
    <key>CFBundleName</key>
    <string>ClipFlow</string>
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
    <string>ClipFlow benötigt Zugriffsrechte, um Text automatisch einzufügen.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
PLIST

echo ""
echo "✅ Fertig! Starte mit:"
echo "   open ClipFlow.app"
echo ""
echo "⚠️  Beim ersten Start: Systemeinstellungen → Datenschutz & Sicherheit"
echo "   → Bedienungshilfen → ClipFlow aktivieren"
