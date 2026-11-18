#!/bin/bash

# KeePassXC with the vault folder synced from Google Drive.
# The vault stays a normal local file (works offline, safe saves), synced both ways with rclone bisync
# by a systemd user timer. Full documentation: docs/keepass-gdrive.config.md
#
# Optional environment variables:
#   RCLONE_REMOTE            rclone remote name for Google Drive        (default: gdrive)
#   RCLONE_DRIVE_CLIENT_ID   own Google OAuth client id for rclone      (default: rclone's shared one)
#   RCLONE_DRIVE_CLIENT_SECRET
#   KEEPASS_REMOTE_DIR       vault folder inside Google Drive           (default: KeePass)
#   KEEPASS_LOCAL_DIR        local vault folder                         (default: ~/Documents/Keepass)
#   KEEPASS_SYNC_INTERVAL    sync interval of the systemd timer         (default: 5min)

set -euo pipefail

declare -r local_bin=$HOME/.local/bin
declare -r rclone=$local_bin/rclone
declare -r systemd_user_dir=$HOME/.config/systemd/user

declare -r rclone_remote=${RCLONE_REMOTE:-gdrive}
declare -r keepass_remote_dir=${KEEPASS_REMOTE_DIR:-KeePass}
declare -r keepass_local_dir=${KEEPASS_LOCAL_DIR:-$HOME/Documents/Keepass}
declare -r keepass_sync_interval=${KEEPASS_SYNC_INTERVAL:-5min}
declare -r keepass_filter=$HOME/.config/rclone/keepass-filter.txt


log() {
    printf '\n\033[1;34m==> %s\033[0m\n' "$*"
}

warn() {
    printf '\033[1;33m[!] %s\033[0m\n' "$*" >&2
}

is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

apt_install() {
    # apt_install <packages...>: installs only the missing ones, so reruns need no sudo
    local missing=() pkg
    for pkg in "$@"; do
        is_installed "$pkg" || missing+=("$pkg")
    done
    if (( ${#missing[@]} )); then
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
}


install_rclone() {
    log 'rclone'
    # Official static binary in ~/.local/bin (no sudo, newer than the Ubuntu package), SHA-256 checked
    local arch latest current dir zip
    case $(uname -m) in
        x86_64) arch=amd64 ;;
        aarch64) arch=arm64 ;;
        *) warn "Unsupported architecture $(uname -m) for rclone"; return 1 ;;
    esac

    latest=$(curl -fsSL https://downloads.rclone.org/version.txt | awk '{print $2}')
    current=$("$rclone" version 2>/dev/null | awk 'NR==1 {print $2}' || true)
    if [[ $current == "$latest" ]]; then
        echo "rclone $current is up to date"
        return 0
    fi

    echo "Installing rclone $latest into $local_bin"
    dir=$(mktemp -d)
    zip=rclone-$latest-linux-$arch.zip
    curl -fsSL -o "$dir/$zip" "https://downloads.rclone.org/$latest/$zip"
    curl -fsSL -o "$dir/SHA256SUMS" "https://downloads.rclone.org/$latest/SHA256SUMS"
    (cd "$dir" && grep " $zip\$" SHA256SUMS | sha256sum --check --status) \
        || { warn 'rclone checksum mismatch'; rm -rf "$dir"; return 1; }
    unzip -q "$dir/$zip" -d "$dir"
    mkdir -p "$local_bin"
    install -m 755 "$dir/rclone-$latest-linux-$arch/rclone" "$rclone"
    rm -rf "$dir"
}

configure_remote() {
    log "rclone remote '$rclone_remote' (Google Drive)"
    if "$rclone" listremotes | grep -qx "$rclone_remote:"; then
        echo 'Already configured'
        return 0
    fi
    echo 'Authorize rclone in the browser that opens.'
    local extra=()
    [[ -n ${RCLONE_DRIVE_CLIENT_ID:-} ]] && extra+=("client_id=$RCLONE_DRIVE_CLIENT_ID")
    [[ -n ${RCLONE_DRIVE_CLIENT_SECRET:-} ]] && extra+=("client_secret=$RCLONE_DRIVE_CLIENT_SECRET")
    # Output discarded: rclone prints the OAuth token
    "$rclone" config create "$rclone_remote" drive scope=drive "${extra[@]}" < /dev/tty > /dev/null
    chmod 600 "$HOME/.config/rclone/rclone.conf"
}

initial_sync() {
    log "Sync $rclone_remote:$keepass_remote_dir <-> $keepass_local_dir"
    # Only vault files: Drive allows duplicate names, which break bisync, so everything else is excluded
    mkdir -p "$(dirname "$keepass_filter")"
    cat <<'FILTER' > "$keepass_filter"
+ *.kdbx
+ *.keyx
- **
FILTER

    mkdir -p "$keepass_local_dir"
    chmod 700 "$keepass_local_dir"

    # The first run needs --resync to create the baseline. "newer" keeps the most recent copy when the
    # same file already exists on both sides (e.g. setting up a second computer).
    local state_name="${rclone_remote}_${keepass_remote_dir}..${keepass_local_dir#/}"
    state_name=${state_name//\//_}
    if ls "$HOME/.cache/rclone/bisync/$state_name".path1.lst >/dev/null 2>&1; then
        echo 'Baseline already exists'
        return 0
    fi
    "$rclone" bisync "$rclone_remote:$keepass_remote_dir" "$keepass_local_dir" \
        --filters-file "$keepass_filter" --resync --resync-mode newer -v
}

install_timer() {
    log "systemd timer (every $keepass_sync_interval)"
    mkdir -p "$systemd_user_dir"
    cat <<UNIT > "$systemd_user_dir/keepass-sync.service"
[Unit]
Description=Sync KeePass vaults with Google Drive (rclone bisync)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$rclone bisync $rclone_remote:$keepass_remote_dir $keepass_local_dir \\
  --filters-file $keepass_filter \\
  --resilient --recover --max-lock 2m \\
  --conflict-resolve none --conflict-loser num \\
  --log-level NOTICE
UNIT
    cat <<UNIT > "$systemd_user_dir/keepass-sync.timer"
[Unit]
Description=Run keepass-sync every $keepass_sync_interval

[Timer]
OnBootSec=1min
OnUnitActiveSec=$keepass_sync_interval
Persistent=true

[Install]
WantedBy=timers.target
UNIT
    systemctl --user daemon-reload
    systemctl --user enable --now keepass-sync.timer
    systemctl --user start keepass-sync.service
}

set_ini_keys() {
    # set_ini_keys <file> <section> <key=value>...: sets keys in a Qt-style ini without touching the rest
    python3 -I - "$@" <<'PY'
import os, sys
path, section, pairs = sys.argv[1], sys.argv[2], dict(p.split("=", 1) for p in sys.argv[3:])
lines = open(path).read().splitlines() if os.path.exists(path) else []
header = f"[{section}]"
if header not in lines:
    lines = [header] + lines
start = lines.index(header) + 1
end = next((i for i in range(start, len(lines)) if lines[i].startswith("[")), len(lines))
for key, value in pairs.items():
    for i in range(start, end):
        if lines[i].split("=", 1)[0] == key:
            lines[i] = f"{key}={value}"
            break
    else:
        lines.insert(start, f"{key}={value}")
        end += 1
os.makedirs(os.path.dirname(path), exist_ok=True)
open(path, "w").write("\n".join(lines) + "\n")
PY
}

configure_keepassxc() {
    log 'KeePassXC settings'
    # Save the vault on every change and reload it when the sync replaces the file.
    # KeePassXC rewrites this file on exit, so it should be closed while this runs.
    pgrep -x keepassxc >/dev/null && warn 'KeePassXC is open: close it, or its settings may overwrite these.'
    set_ini_keys "$HOME/.config/keepassxc/keepassxc.ini" General \
        AutoSaveAfterEveryChange=true AutoReloadOnChange=true
}

main() {
    log 'Packages'
    apt_install keepassxc unzip curl python3
    install_rclone
    configure_remote
    initial_sync
    install_timer
    configure_keepassxc

    log 'Done'
    echo "Vaults in $keepass_local_dir, synced every $keepass_sync_interval."
    echo 'Sync now: systemctl --user start keepass-sync   Logs: journalctl --user -u keepass-sync'
}

# Everything runs from here, so bash has read the whole script before any command reads from stdin
main "$@"
