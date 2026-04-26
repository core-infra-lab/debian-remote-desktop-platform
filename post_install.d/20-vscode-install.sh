#!/bin/sh
set -eu

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive

if command -v code >/dev/null 2>&1; then
  echo "VS Code is already installed: $(code --version | head -n 1)"
  exit 0
fi

echo "Installing VS Code APT repository prerequisites..."
$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  gpg \
  wget

echo "Installing Microsoft signing key..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor \
  | $SUDO install -D -o root -g root -m 644 /dev/stdin /usr/share/keyrings/microsoft.gpg

echo "Adding VS Code APT repository..."
$SUDO tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

echo "Installing VS Code..."
$SUDO apt-get update
$SUDO apt-get install -y code

echo "VS Code installed successfully."
