#!/bin/bash

# https://gnunn1.github.io/tilix-web/

set -euo pipefail

declare sysutilsrc=$HOME/.sysutils/sysutilsrc;
declare script_dir; script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd);

echo 'Installing Tilix';
sudo apt update;
sudo apt install -y tilix;

echo 'Setting Tilix as default terminal';
alternative=$(update-alternatives --list x-terminal-emulator 2>/dev/null | grep -m1 tilix || true);
[[ -n $alternative ]] && sudo update-alternatives --set x-terminal-emulator "$alternative";

# Ubuntu 25.10+ opens the terminal (Ctrl+Alt+T, "Open in Terminal") through xdg-terminal-exec
declare entry=com.gexperts.Tilix.desktop;
for list in "$HOME/.config/xdg-terminals.list" "$HOME/.config/ubuntu-xdg-terminals.list"; do
    touch "$list";
    grep -vxF "$entry" "$list" > "$list.tmp" || true;
    { echo "$entry"; cat "$list.tmp"; } > "$list";
    rm -f "$list.tmp";
done
# GNOME's legacy setting, still used by some apps
gsettings set org.gnome.desktop.default-applications.terminal exec 'tilix' 2>/dev/null || true;

# https://gnunn1.github.io/tilix-web/manual/vteconfig/
if [[ -f $script_dir/../config/sysutilsrc.config.sh ]]; then
    bash "$script_dir/../config/sysutilsrc.config.sh";
else
    wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;
fi
declare rcline='if [ -n "$TILIX_ID" ] || [ -n "$VTE_VERSION" ]; then [ -f /etc/profile.d/vte-2.91.sh ] && . /etc/profile.d/vte-2.91.sh; fi';
grep -qxF "$rcline" "$sysutilsrc" || printf "%s\n" "$rcline" >> "$sysutilsrc";
