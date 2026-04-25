#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build_dmg.sh — Baut ClipFlow.app und verpackt sie als verteilbares DMG
#
# Verwendung:
#   chmod +x build_dmg.sh
#   ./build_dmg.sh
#
# Ergebnis: ClipFlow-1.0.dmg im Projektverzeichnis
# ---------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="1.1"
APP_NAME="ClipFlow"
BUNDLE_ID="local.misgin.clipflow"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"
DMG_PATH="${SCRIPT_DIR}/${DMG_NAME}"

# ---------------------------------------------------------------------------
# 1. Release-Build (Universal Binary: arm64 + x86_64)
# ---------------------------------------------------------------------------
echo "🔨  Baue ${APP_NAME} ${VERSION} (Universal Binary) …"
cd "$SCRIPT_DIR"

swift build -c release --arch arm64  2>&1
swift build -c release --arch x86_64 2>&1

ARM_BIN="${SCRIPT_DIR}/.build/arm64-apple-macosx/release/${APP_NAME}"
X86_BIN="${SCRIPT_DIR}/.build/x86_64-apple-macosx/release/${APP_NAME}"

# Falls nur eine Architektur verfügbar ist, wird nur diese verwendet
if [[ -f "$ARM_BIN" && -f "$X86_BIN" ]]; then
    echo "🔗  Verbinde zu Universal Binary …"
    MERGED_BIN="${SCRIPT_DIR}/.build/${APP_NAME}_universal"
    lipo -create -output "$MERGED_BIN" "$ARM_BIN" "$X86_BIN"
    FINAL_BIN="$MERGED_BIN"
elif [[ -f "$ARM_BIN" ]]; then
    echo "ℹ️   Nur arm64 verfügbar."
    FINAL_BIN="$ARM_BIN"
else
    echo "ℹ️   Nur x86_64 verfügbar."
    FINAL_BIN="$X86_BIN"
fi

# ---------------------------------------------------------------------------
# 2. .app-Bundle aufbauen
# ---------------------------------------------------------------------------
echo "📦  Erstelle ${APP_NAME}.app …"
rm -rf "$BUNDLE"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp "$FINAL_BIN" "${BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${BUNDLE}/Contents/MacOS/${APP_NAME}"

# Icon kopieren (falls vorhanden)
ICNS_SRC="${SCRIPT_DIR}/Sources/ClipboardManager/Resources/AppIcon.icns"
if [[ -f "$ICNS_SRC" ]]; then
    cp "$ICNS_SRC" "${BUNDLE}/Contents/Resources/AppIcon.icns"
    echo "   🎨  Icon eingebunden."
else
    echo "   ⚠️   Kein AppIcon.icns gefunden – führe zuerst make_icon.py aus."
fi

# Info.plist
cat > "${BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 Alexander Misgin. Alle Rechte vorbehalten.</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <!-- Kein Dock-Icon; läuft als Menüleisten-App -->
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <!-- Pflichttext für Bedienungshilfen-Zugriff (⌘V-Simulation) -->
    <key>NSAccessibilityUsageDescription</key>
    <string>ClipFlow benötigt Zugriff auf die Bedienungshilfen, um den Einfüge-Shortcut automatisch auszulösen.</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 Alex Misgin. Alle Rechte vorbehalten.</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST

# ---------------------------------------------------------------------------
# 3. Codesignierung
#    "ClipFlow Dev"-Zertifikat bevorzugen (stabiler → Berechtigung bleibt
#    nach Updates bestehen). Fallback auf Ad-hoc.
# ---------------------------------------------------------------------------
echo "🔏  Codesignierung …"
if security find-identity -v -p codesigning | grep -q "ClipFlow Dev"; then
    codesign --force --deep --sign "ClipFlow Dev" "${BUNDLE}" && echo "   ✓  Signiert mit 'ClipFlow Dev'."
else
    codesign --force --deep --sign - "${BUNDLE}" && echo "   ✓  Ad-hoc signiert." || echo "   ⚠️  codesign nicht verfügbar."
fi

# ---------------------------------------------------------------------------
# 4. DMG erstellen
# ---------------------------------------------------------------------------
echo "💿  Erstelle ${DMG_NAME} …"

TMP_DIR="$(mktemp -d)"
cp -R "$BUNDLE" "${TMP_DIR}/"
# Symlink → /Applications für Drag-to-install
ln -s /Applications "${TMP_DIR}/Applications"

# Altes DMG entfernen falls vorhanden
rm -f "$DMG_PATH"

hdiutil create \
    -volname "${APP_NAME} ${VERSION}" \
    -srcfolder "${TMP_DIR}" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

rm -rf "$TMP_DIR"

# ---------------------------------------------------------------------------
# 4. Fertig
# ---------------------------------------------------------------------------
echo ""
echo "✅  Fertig!"
echo "   DMG:  ${DMG_PATH}"
echo "   App:  ${BUNDLE}"
echo ""
echo "   Zum Installieren: DMG öffnen → ClipFlow in den Applications-Ordner ziehen."
echo ""
echo "⚠️  Gatekeeper-Hinweis für Empfänger:"
echo "   Da die App nicht von Apple notarisiert ist, erscheint beim ersten Start"
echo "   eine Warnung. Lösung: Rechtsklick auf ClipFlow.app → 'Öffnen' → 'Trotzdem öffnen'."
echo "   (Oder: Systemeinstellungen → Datenschutz & Sicherheit → 'Trotzdem öffnen')"
