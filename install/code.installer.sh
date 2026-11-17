#!/bin/bash

# https://code.visualstudio.com/docs/setup/linux

set -euo pipefail

sudo apt-get update;
sudo apt-get install -y wget gpg;

tmp=$(mktemp -d);
trap 'rm -rf "$tmp"' EXIT;
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$tmp/microsoft.gpg";
sudo install -D -o root -g root -m 644 "$tmp/microsoft.gpg" /usr/share/keyrings/microsoft.gpg;

# Old one-line repository format, replaced by vscode.sources
sudo rm -f /etc/apt/sources.list.d/vscode.list;
sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<SOURCES
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
SOURCES

# The repository is already configured above, so the package must not add another one
echo "code code/add-microsoft-repo boolean false" | sudo debconf-set-selections;

sudo apt-get update;
sudo apt-get install -y code;

# "Open in Code" in the Nautilus context menu
# https://github.com/harry-cpp/code-nautilus (also installs python3-nautilus)
wget -qO- https://raw.githubusercontent.com/harry-cpp/code-nautilus/master/install.sh | bash;
