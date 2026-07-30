#!/bin/bash
set -euo pipefail

# Create directories
mkdir -p "$(dirname "$0")/certs"
mkdir -p "$(dirname "$0")/profiles"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CERTS_DIR="$SCRIPT_DIR/certs"
PROFILES_DIR="$SCRIPT_DIR/profiles"

# Generate self-signed certificate and key
echo "Generating self-signed certificate for code signing..."
openssl req -x509 -newkey rsa:2048 -keyout "$CERTS_DIR/SelfSigned.key" \
  -out "$CERTS_DIR/SelfSigned.cer" -days 3650 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=Apple Application"

# Create PKCS12 from certificate and key
openssl pkcs12 -export -in "$CERTS_DIR/SelfSigned.cer" \
  -inkey "$CERTS_DIR/SelfSigned.key" \
  -out "$CERTS_DIR/SelfSigned.p12" -name "Apple Application" -passout pass:

echo "Certificate generated successfully at $CERTS_DIR/SelfSigned.p12"
echo "Key fingerprint:"
openssl x509 -fingerprint -noout -in "$CERTS_DIR/SelfSigned.cer"
