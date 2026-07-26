#!/bin/bash
# ---------------------------------------------------------------------------
# setup_dev_cert.sh – Erstellt einmalig ein lokales Code-Signing-Zertifikat
#
# Problem ohne dieses Skript:
#   macOS bindet die Bedienungshilfen-Berechtigung an die Code-Signatur.
#   Bei Ad-hoc-Signierung (--sign -) ändert sich die Signatur bei jedem
#   Rebuild → Berechtigung muss jedes Mal neu erteilt werden.
#
# Mit diesem Skript:
#   "ClipFlow Dev"-Zertifikat ist stabil → Berechtigung wird einmalig
#   erteilt und bleibt bei jedem Rebuild dauerhaft bestehen.
#
# Verwendung: Einmalig ausführen, dann ./build.sh wie gewohnt.
# ---------------------------------------------------------------------------
set -e

CERT_NAME="ClipFlow Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

# Schon vorhanden?
if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo "✅ Zertifikat '$CERT_NAME' ist bereits vorhanden."
    echo "   Kein weiterer Schritt nötig."
    exit 0
fi

echo "🔑 Erstelle lokales Code-Signing-Zertifikat '$CERT_NAME'..."

# OpenSSL-Config
cat > /tmp/clipflow_cert.conf << 'EOF'
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
x509_extensions    = v3_req

[dn]
CN = ClipFlow Dev

[v3_req]
keyUsage         = critical, digitalSignature
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
basicConstraints = CA:false
EOF

# Schlüssel + selbst-signiertes Zertifikat erzeugen
openssl req -x509 -newkey rsa:2048 \
    -keyout /tmp/clipflow_dev.key \
    -out    /tmp/clipflow_dev.crt \
    -days   3650 -nodes \
    -config /tmp/clipflow_cert.conf 2>/dev/null

# Als PKCS12 bündeln
openssl pkcs12 -export \
    -out    /tmp/clipflow_dev.p12 \
    -inkey  /tmp/clipflow_dev.key \
    -in     /tmp/clipflow_dev.crt \
    -passout pass:clipflowdev 2>/dev/null

# In Keychain importieren (codesign darf es verwenden)
security import /tmp/clipflow_dev.p12 \
    -k "$KEYCHAIN" \
    -P clipflowdev \
    -T /usr/bin/codesign \
    -f pkcs12 2>/dev/null

# Als vertrauenswürdig markieren (benötigt Admin-Passwort)
security add-trusted-cert \
    -d -r trustRoot \
    -k "$KEYCHAIN" \
    /tmp/clipflow_dev.crt

# Aufräumen
rm -f /tmp/clipflow_dev.{key,crt,p12} /tmp/clipflow_cert.conf

echo ""
echo "✅ Fertig! Zertifikat '$CERT_NAME' ist einsatzbereit."
echo ""
echo "Nächste Schritte:"
echo "  1. ./build.sh             – baut und signiert mit stabilem Zertifikat"
echo "  2. App installieren und starten"
echo "  3. Bedienungshilfen einmalig erteilen (Systemeinstellungen →"
echo "     Datenschutz & Sicherheit → Bedienungshilfen → ClipFlow)"
echo ""
echo "Ab sofort bleibt die Berechtigung nach jedem Rebuild erhalten."
