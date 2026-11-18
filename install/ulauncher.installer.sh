#!/bin/bash

# Ulauncher (https://ulauncher.io) from its PPA, started at login.
# The Cmd+Space shortcut (ulauncher-toggle) is set by config/mac-keyboard.config.sh: Ulauncher's own
# hotkey does not work on Wayland.

set -euo pipefail

declare -r autostart=$HOME/.config/autostart/ulauncher.desktop

wait_for_dpkg_lock() {
    # Paseo's auto-updater runs dpkg in the background and can hold the lock for minutes
    while pgrep -x dpkg >/dev/null || pgrep -x apt-get >/dev/null; do
        echo 'Waiting for another apt/dpkg process to finish...'
        sleep 5
    done
}

main() {
    if dpkg-query -W -f='${Status}' ulauncher 2>/dev/null | grep -q 'install ok installed'; then
        echo 'Ulauncher is already installed.'
    else
        echo 'Installing Ulauncher'
        wait_for_dpkg_lock
        sudo apt-get update
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:agornostal/ulauncher
        sudo apt-get update
        sudo apt-get install -y ulauncher
    fi

    if [[ ! -f $autostart ]]; then
        mkdir -p "$(dirname "$autostart")"
        cat <<'DESKTOP' > "$autostart"
[Desktop Entry]
Type=Application
Name=Ulauncher
Exec=env GDK_BACKEND=x11 /usr/bin/ulauncher --autostart-method-xdg --hide-window
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
        echo "Autostart entry created: $autostart"
    fi

    # Start it now (hidden) if it is not running yet
    pgrep -f /usr/bin/ulauncher >/dev/null || (setsid ulauncher --hide-window >/dev/null 2>&1 &)

    echo 'Cmd+Space shortcut: run config/mac-keyboard.config.sh (or bind "ulauncher-toggle").'
}

main "$@"
