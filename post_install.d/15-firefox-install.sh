#!/bin/sh
set -eu

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive

FIREFOX_PACKAGE="${FIREFOX_PACKAGE:-firefox}"
MOZILLA_KEYRING="/etc/apt/keyrings/packages.mozilla.org.asc"
EXPECTED_FINGERPRINT="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"

if command -v firefox >/dev/null 2>&1; then
  echo "Firefox is already installed: $(firefox --version)"
  exit 0
fi

echo "Installing Firefox APT repository prerequisites..."
$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  ca-certificates \
  gpg \
  wget

echo "Installing Mozilla signing key..."
$SUDO install -d -m 0755 /etc/apt/keyrings
wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg \
  | $SUDO tee "$MOZILLA_KEYRING" >/dev/null

echo "Verifying Mozilla signing key fingerprint..."
ACTUAL_FINGERPRINT="$(gpg -n -q --show-keys --with-colons "$MOZILLA_KEYRING" | awk -F: '$1 == "fpr" { print $10; exit }')"
if [ "$ACTUAL_FINGERPRINT" != "$EXPECTED_FINGERPRINT" ]; then
  echo "Mozilla signing key fingerprint mismatch: $ACTUAL_FINGERPRINT" >&2
  exit 1
fi

echo "Adding Mozilla APT repository..."
$SUDO tee /etc/apt/sources.list.d/mozilla.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF

echo "Prioritizing Mozilla packages..."
$SUDO tee /etc/apt/preferences.d/mozilla >/dev/null <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

echo "Installing Firefox package: ${FIREFOX_PACKAGE}..."
$SUDO apt-get update
$SUDO apt-get install -y "$FIREFOX_PACKAGE"

echo "Firefox installed successfully."
