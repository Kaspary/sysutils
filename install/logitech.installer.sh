#!/bin/bash

# Logitech Easy-Switch sync for Linux (Logi Options+ has no Linux version).
# Installs Solaar and a user service that sends the mouse to the same Easy-Switch
# channel when the keyboard is switched to another computer.
# https://pwr-solaar.github.io/Solaar/
#
# Optional environment variables (otherwise the script asks):
#   LOGI_KEYBOARD_MAC   Bluetooth address of the keyboard
#   LOGI_MOUSE_NAME     mouse name as shown by `solaar show`
#   LOGI_TARGET_HOST    Easy-Switch channel (1-3) of the other computer

set -euo pipefail

declare sysutils=$HOME/.sysutils;
declare follow_script=$sysutils/logitech-follow-keyboard.sh;
declare service_dir=$HOME/.config/systemd/user;
declare service=logitech-follow-keyboard.service;

ask() {
    # ask <prompt> <default>: reads from the terminal, so it also works when piped to bash
    local answer=;
    if [[ -r /dev/tty ]]; then
        read -r -p "$1 [$2]: " answer < /dev/tty || true;
    fi
    echo "${answer:-$2}";
}

echo 'Installing Solaar';
sudo apt update;
sudo apt install -y solaar bluez libglib2.0-bin;

# Solaar needs access to /dev/hidraw*; the package ships the udev rule, apply it to devices already connected
sudo udevadm control --reload-rules;
sudo udevadm trigger --subsystem-match=hidraw --action=change;

echo 'Paired Bluetooth devices:';
bluetoothctl devices;

declare keyboard_guess; keyboard_guess=$(bluetoothctl devices | grep -i -m1 -E 'keys|keyboard' | awk '{print $2}' || true);
declare mouse_guess; mouse_guess=$(bluetoothctl devices | grep -i -m1 -E 'master|anywhere|mouse' | cut -d' ' -f3- || true);

declare keyboard_mac=${LOGI_KEYBOARD_MAC:-$(ask 'Keyboard Bluetooth address' "$keyboard_guess")};
declare mouse_name=${LOGI_MOUSE_NAME:-$(ask 'Mouse name (see solaar show)' "${mouse_guess:-MX Master 3S}")};
declare target_host=${LOGI_TARGET_HOST:-$(ask 'Easy-Switch channel of the other computer (1-3)' 1)};

if [[ ! $keyboard_mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
    echo "Invalid keyboard Bluetooth address: '$keyboard_mac'" >&2;
    exit 1;
fi
if [[ ! $target_host =~ ^[1-3]$ ]]; then
    echo "Invalid Easy-Switch channel: '$target_host'" >&2;
    exit 1;
fi

mkdir -p "$sysutils" "$service_dir";

cat <<'SCRIPT' > "$follow_script"
#!/bin/bash
# Usage: logitech-follow-keyboard.sh <keyboard_mac> <mouse_name> <target_host>
# When the keyboard disconnects from this computer (Easy-Switch), moves the mouse to the same channel.
keyboard_mac=$1
mouse_name=$2
target_host=$3

device_path=$(busctl --system tree org.bluez --list | grep -m1 "/dev_${keyboard_mac//:/_}\$")
if [[ -z $device_path ]]; then
    echo "Keyboard $keyboard_mac is not paired with this computer" >&2
    exit 1
fi

echo "Watching $device_path; '$mouse_name' goes to channel $target_host when the keyboard disconnects"

gdbus monitor --system --dest org.bluez --object-path "$device_path" |
while read -r line; do
    if [[ $line == *"'Connected': <false>"* ]]; then
        echo "Keyboard disconnected; moving '$mouse_name' to channel $target_host"
        # Solaar 1.1.x applies the change and then raises a TypeError (CLI bug), so the exit code is ignored
        solaar config "$mouse_name" change-host "$target_host" 2>&1 | grep -E 'Setting change-host' || echo 'no confirmation from solaar'
    fi
done
SCRIPT
chmod +x "$follow_script";

cat <<UNIT > "$service_dir/$service"
[Unit]
Description=Move the Logitech mouse along with the keyboard Easy-Switch
After=bluetooth.target

[Service]
ExecStart=$follow_script $keyboard_mac "$mouse_name" $target_host
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
UNIT

systemctl --user daemon-reload;
systemctl --user enable --now "$service";

echo "Done. When the keyboard leaves this computer, '$mouse_name' goes to channel $target_host.";
echo 'Coming back needs the mouse Easy-Switch button (or the same setup on the other computer).';
echo "Logs: journalctl --user -u $service -f";
echo 'If Solaar does not see the devices, reconnect them via Bluetooth so the udev permissions are applied.';
