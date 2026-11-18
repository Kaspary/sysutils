#!/bin/bash

# Ubuntu desktop setup (GNOME on Wayland) with my personal preferences.
# Full documentation (what each step changes, how to revert, how to update): docs/ubuntu.config.md
#
# Steps (run in this order; each one is idempotent and can be run on its own):
#   keyboard   layouts "br" + "English (intl., with AltGr dead keys)"
#   keepass    KeePassXC + rclone bisync of the Google Drive vault folder (systemd timer, every 5 min)
#   paseo      Paseo desktop (.deb from GitHub releases; it updates itself afterwards)
#   toshy      Toshy (macOS-like shortcuts) + Xremap GNOME extension + my Toshy overrides
#   ulauncher  Ulauncher (PPA), opened with Cmd+Space
#   handy      Handy speech-to-text (.deb from GitHub releases), toggled with Option+Space
#
# Usage:
#   all steps:       curl -L <raw url> | tr -d '\r' | bash
#   selected steps:  curl -L <raw url> | tr -d '\r' | bash -s -- keyboard toshy
#   list steps:      ... | bash -s -- help
#
# Optional environment variables:
#   RCLONE_REMOTE            rclone remote name for Google Drive        (default: gdrive)
#   RCLONE_DRIVE_CLIENT_ID   own Google OAuth client id for rclone      (default: rclone's shared one)
#   RCLONE_DRIVE_CLIENT_SECRET
#   KEEPASS_REMOTE_DIR       vault folder inside Google Drive           (default: KeePass)
#   KEEPASS_LOCAL_DIR        local vault folder                         (default: ~/Documents/Keepass)
#   KEEPASS_SYNC_INTERVAL    sync interval of the systemd timer         (default: 5min)
#   TOSHY_REINSTALL=1        run the Toshy installer even if Toshy is already installed

set -euo pipefail

declare -r all_steps=(keyboard keepass paseo toshy ulauncher handy)

declare -r sysutils=$HOME/.sysutils
declare -r local_bin=$HOME/.local/bin
declare -r systemd_user_dir=$HOME/.config/systemd/user
declare -r autostart_dir=$HOME/.config/autostart

declare -r rclone_remote=${RCLONE_REMOTE:-gdrive}
declare -r keepass_remote_dir=${KEEPASS_REMOTE_DIR:-KeePass}
declare -r keepass_local_dir=${KEEPASS_LOCAL_DIR:-$HOME/Documents/Keepass}
declare -r keepass_sync_interval=${KEEPASS_SYNC_INTERVAL:-5min}
declare -r keepass_filter=$HOME/.config/rclone/keepass-filter.txt

declare -r toshy_dir=$HOME/.config/toshy
declare -r toshy_config=$toshy_dir/toshy_config.py
declare -r toshy_prefs=$toshy_dir/toshy_user_preferences.sqlite
declare -r xremap_extension=xremap@k0kubun.com

declare -r keybindings_schema=org.gnome.settings-daemon.plugins.media-keys
declare -r keybindings_path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log() {
    printf '\n\033[1;34m==> %s\033[0m\n' "$*"
}

warn() {
    printf '\033[1;33m[!] %s\033[0m\n' "$*" >&2
}

ask() {
    # ask <prompt> <default>: reads from the terminal, so it also works when piped to bash
    local answer=
    if [[ -r /dev/tty ]]; then
        read -r -p "$1 [$2]: " answer < /dev/tty || true
    fi
    echo "${answer:-$2}"
}

is_installed() {
    # is_installed <deb package>
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

apt_install() {
    # apt_install <packages...>: installs only the missing ones, so reruns need no sudo
    local missing=()
    local pkg
    for pkg in "$@"; do
        is_installed "$pkg" || missing+=("$pkg")
    done
    if (( ${#missing[@]} )); then
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
}

wait_for_dpkg_lock() {
    # Paseo's auto-updater runs dpkg in the background and can hold the lock for minutes
    local waited=0
    while pgrep -x dpkg >/dev/null || pgrep -x apt-get >/dev/null; do
        (( waited == 0 )) && warn 'Another apt/dpkg process is running (Paseo updater?). Waiting for it to finish...'
        sleep 5
        waited=$((waited + 5))
    done
}

install_github_deb() {
    # install_github_deb <owner/repo> <asset regex>
    # Downloads the latest release asset matching the regex, checks the SHA-256 digest published by
    # GitHub and installs it with apt (which also pulls the dependencies).
    local repo=$1 pattern=$2 dir name url digest
    dir=$(mktemp -d)
    chmod 755 "$dir"   # lets apt's sandbox user read the file

    read -r name url digest < <(
        curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
        python3 -I -c '
import json, re, sys
pattern = re.compile(sys.argv[1])
for asset in json.load(sys.stdin)["assets"]:
    if pattern.search(asset["name"]):
        print(asset["name"], asset["browser_download_url"], asset.get("digest") or "-")
        break
' "$pattern"
    )
    if [[ -z ${name:-} ]]; then
        warn "No release asset of $repo matches '$pattern'"
        rm -rf "$dir"
        return 1
    fi

    echo "Downloading $name"
    curl -fL --progress-bar -o "$dir/$name" "$url"
    if [[ $digest == sha256:* ]]; then
        echo "${digest#sha256:}  $dir/$name" | sha256sum --check --status \
            || { warn "Checksum mismatch for $name"; rm -rf "$dir"; return 1; }
        echo 'Checksum OK'
    else
        warn "GitHub published no digest for $name; installing without checksum verification"
    fi

    wait_for_dpkg_lock
    sudo apt-get install -y "$dir/$name"
    rm -rf "$dir"
}

add_custom_keybinding() {
    # add_custom_keybinding <id> <name> <command> <binding>
    # Creates/updates a GNOME custom shortcut, keeping the other custom shortcuts in the list.
    local id=$1 name=$2 command=$3 binding=$4
    local path="$keybindings_path/$id/"
    local schema="$keybindings_schema.custom-keybinding:$path"
    local current updated

    gsettings set "$schema" name "$name"
    gsettings set "$schema" command "$command"
    gsettings set "$schema" binding "$binding"

    current=$(gsettings get "$keybindings_schema" custom-keybindings)
    updated=$(python3 -I -c '
import ast, sys
paths = ast.literal_eval(sys.argv[1].replace("@as ", ""))
if sys.argv[2] not in paths:
    paths.append(sys.argv[2])
print(repr(paths))
' "$current" "$path")
    gsettings set "$keybindings_schema" custom-keybindings "$updated"
    echo "Shortcut $binding -> $command"
}

write_autostart() {
    # write_autostart <file name> <Name> <Exec>
    mkdir -p "$autostart_dir"
    [[ -f $autostart_dir/$1 ]] && return 0
    cat <<DESKTOP > "$autostart_dir/$1"
[Desktop Entry]
Type=Application
Name=$2
Exec=$3
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
    echo "Autostart entry created: $autostart_dir/$1"
}


# ---------------------------------------------------------------------------
# Step: keyboard
# ---------------------------------------------------------------------------

step_keyboard() {
    log 'Keyboard layouts: br + English (intl., with AltGr dead keys)'
    # us+altgr-intl keeps ' " ` ~ ^ as normal keys (no dead keys on the base level) and puts the
    # dead keys / ç on AltGr. Toshy maps the Option key to these AltGr combos (see step_toshy).
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br'), ('xkb', 'us+altgr-intl')]"
    gsettings get org.gnome.desktop.input-sources sources
}


# ---------------------------------------------------------------------------
# Step: keepass
# ---------------------------------------------------------------------------

install_rclone() {
    # Official static binary in ~/.local/bin (no sudo, newer than the Ubuntu package), SHA-256 checked
    local arch latest current dir zip
    case $(uname -m) in
        x86_64) arch=amd64 ;;
        aarch64) arch=arm64 ;;
        *) warn "Unsupported architecture $(uname -m) for rclone"; return 1 ;;
    esac

    latest=$(curl -fsSL https://downloads.rclone.org/version.txt | awk '{print $2}')
    current=$("$local_bin/rclone" version 2>/dev/null | awk 'NR==1 {print $2}' || true)
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
    install -m 755 "$dir/rclone-$latest-linux-$arch/rclone" "$local_bin/rclone"
    rm -rf "$dir"
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

step_keepass() {
    log 'KeePassXC + Google Drive vault sync (rclone bisync)'
    apt_install keepassxc unzip curl
    install_rclone
    local rclone=$local_bin/rclone

    # Google Drive remote: OAuth in the browser, only the first time
    if ! "$rclone" listremotes | grep -qx "$rclone_remote:"; then
        echo "Creating rclone remote '$rclone_remote'. Authorize it in the browser that opens."
        local extra=()
        [[ -n ${RCLONE_DRIVE_CLIENT_ID:-} ]] && extra+=("client_id=$RCLONE_DRIVE_CLIENT_ID")
        [[ -n ${RCLONE_DRIVE_CLIENT_SECRET:-} ]] && extra+=("client_secret=$RCLONE_DRIVE_CLIENT_SECRET")
        "$rclone" config create "$rclone_remote" drive scope=drive "${extra[@]}" < /dev/tty > /dev/null
        chmod 600 "$HOME/.config/rclone/rclone.conf"
    fi

    # Only vault files: Drive allows duplicate names, which break bisync, so everything else is excluded
    mkdir -p "$(dirname "$keepass_filter")"
    cat <<'FILTER' > "$keepass_filter"
+ *.kdbx
+ *.keyx
- **
FILTER

    mkdir -p "$keepass_local_dir"
    chmod 700 "$keepass_local_dir"

    # First run needs --resync to create the baseline. "newer" keeps the most recent copy when the
    # same file already exists on both sides (e.g. setting up a second computer).
    local state_name
    state_name="${rclone_remote}_${keepass_remote_dir}..${keepass_local_dir#/}"
    state_name=${state_name//\//_}
    if ! ls "$HOME/.cache/rclone/bisync/$state_name".path1.lst >/dev/null 2>&1; then
        echo "Initial sync: $rclone_remote:$keepass_remote_dir <-> $keepass_local_dir"
        "$rclone" bisync "$rclone_remote:$keepass_remote_dir" "$keepass_local_dir" \
            --filters-file "$keepass_filter" --resync --resync-mode newer -v
    fi

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

    # Save the vault on every change and reload it when the sync replaces the file.
    # KeePassXC rewrites this file on exit, so close it before running this step.
    pgrep -x keepassxc >/dev/null && warn 'KeePassXC is open: close it, or its settings may overwrite these.'
    set_ini_keys "$HOME/.config/keepassxc/keepassxc.ini" General \
        AutoSaveAfterEveryChange=true AutoReloadOnChange=true

    echo "Vaults in $keepass_local_dir, synced every $keepass_sync_interval."
    echo 'Sync now: systemctl --user start keepass-sync   Logs: journalctl --user -u keepass-sync'
}


# ---------------------------------------------------------------------------
# Step: paseo
# ---------------------------------------------------------------------------

step_paseo() {
    log 'Paseo'
    if is_installed paseo; then
        echo 'Paseo already installed (it updates itself).'
        return 0
    fi
    install_github_deb getpaseo/paseo "^Paseo-.*-$(dpkg --print-architecture)\\.deb\$"
}


# ---------------------------------------------------------------------------
# Step: toshy
# ---------------------------------------------------------------------------

# Content of the "user_apps" slice of toshy_config.py. Toshy keeps this slice when it is reinstalled
# or upgraded. Key names: "Alt" = Option, "RC" = Cmd, "RAlt" = AltGr of us+altgr-intl.
IFS= read -r -d '' toshy_user_apps_slice <<'SLICE' || true


keymap("User hardware keys", {
    # PUT UNIVERSAL REMAPS FOR HARDWARE KEYS HERE
    # KEYMAP WILL BE ACTIVE IN ALL DESKTOP ENVIRONMENTS/DISTROS


}, when = lambda ctx:
    cnfg.screen_has_focus and
    not ctx_app_is_remote
)

# [sysutils] Mac-style accents with the NATIVE dead keys of us+altgr-intl (AltGr = RAlt).
# Replaces Toshy's OptSpecChars, which types unicode codes and fails in Electron apps.
keymap("User overrides: acentos Option", {
    C("Alt-c"):                 C("RAlt-Comma"),                # ç
    C("Shift-Alt-c"):           C("Shift-RAlt-Comma"),          # Ç
    C("Alt-e"):                 C("RAlt-Apostrophe"),           # ´ (dead) -> á é í ó ú
    C("Alt-i"):                 C("RAlt-Key_6"),                # ^ (dead) -> â ê ô
    C("Alt-n"):                 C("Shift-RAlt-Grave"),          # ~ (dead) -> ã õ
    C("Alt-Grave"):             C("RAlt-Grave"),                # ` (dead) -> à
    C("Alt-u"):                 C("Shift-RAlt-Apostrophe"),     # ¨ (dead) -> ü
    C("Alt-Space"):             C("Alt-Space"),                 # Option+Space -> Handy (GNOME shortcut), no per-app remap
}, when = lambda ctx:
    cnfg.screen_has_focus and
    not ctx_app_is_remote
)

# [sysutils] Cmd+Space opens Ulauncher (GNOME custom shortcut: Shift+Ctrl+Space -> ulauncher-toggle).
# Without this, Toshy sends whatever GNOME's toggle-overview shortcut is.
keymap("User overrides: Ulauncher", {
    C("RC-Space"):              [iEF2NT(), C("Shift-C-Space")],
}, when = lambda ctx:
    cnfg.screen_has_focus and
    not ctx_app_is_remote
)

SLICE

install_xremap_extension() {
    # Toshy needs a GNOME extension on Wayland to know the focused window
    if gnome-extensions info "$xremap_extension" >/dev/null 2>&1; then
        echo "GNOME extension $xremap_extension already installed"
        gnome-extensions enable "$xremap_extension" 2>/dev/null || true
        return 0
    fi
    echo "Installing GNOME extension $xremap_extension (confirm the dialog that GNOME shows)"
    # Call it only once: installing twice in the same session leaves the extension in ERROR until re-login
    gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell \
        --method org.gnome.Shell.Extensions.InstallRemoteExtension "$xremap_extension"
}

install_toshy() {
    local dir
    dir=$(mktemp -d)
    echo "Downloading Toshy into $dir"
    curl -fsSL -o "$dir/toshy.zip" https://github.com/RedBearAK/toshy/archive/refs/heads/main.zip
    # unzip (not Python's zipfile) keeps the executable bits the installer depends on
    unzip -q "$dir/toshy.zip" -d "$dir"
    wait_for_dpkg_lock
    (cd "$dir"/[Tt]oshy-main && ./setup_toshy.py install < /dev/tty)
    rm -rf "$dir"
}

apply_toshy_overrides() {
    # Replaces the user_apps slice and turns off Toshy's unicode-based Option special characters
    TOSHY_SLICE=$toshy_user_apps_slice python3 -I - "$toshy_config" <<'PY'
import os, re, sys
path = sys.argv[1]
text = open(path).read()
pattern = re.compile(r"(###  SLICE_MARK_START: user_apps  ###[^\n]*\n)(.*?)(###  SLICE_MARK_END: user_apps  ###)", re.S)
if not pattern.search(text):
    sys.exit(f"user_apps slice markers not found in {path}")
text = pattern.sub(lambda m: m.group(1) + os.environ["TOSHY_SLICE"] + m.group(3), text, count=1)
open(path, "w").write(text)
PY
    "$toshy_dir/.venv/bin/python" -m py_compile "$toshy_config"

    python3 -I - "$toshy_prefs" <<'PY'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
db.execute("CREATE TABLE IF NOT EXISTS config_preferences (name TEXT PRIMARY KEY, value TEXT)")
db.execute("INSERT OR REPLACE INTO config_preferences (name, value) VALUES ('optspec_layout', 'Disabled')")
db.commit()
PY

    if systemctl --user is-active --quiet toshy-config.service; then
        systemctl --user restart toshy-config.service
    fi
    echo 'Toshy overrides applied (Option accents, Option+Space, Cmd+Space).'
}

step_toshy() {
    log 'Toshy (macOS-like shortcuts)'
    apt_install unzip curl python3
    install_xremap_extension

    if [[ ! -f $toshy_config || ${TOSHY_REINSTALL:-0} == 1 ]]; then
        install_toshy
    else
        echo 'Toshy already installed (TOSHY_REINSTALL=1 forces the installer).'
    fi
    apply_toshy_overrides
}


# ---------------------------------------------------------------------------
# Step: ulauncher
# ---------------------------------------------------------------------------

step_ulauncher() {
    log 'Ulauncher (Cmd+Space)'
    if ! is_installed ulauncher; then
        apt_install software-properties-common
        sudo add-apt-repository -y ppa:agornostal/ulauncher
        wait_for_dpkg_lock
        sudo apt-get update
        sudo apt-get install -y ulauncher
    fi

    # Ulauncher's own hotkey does not work on Wayland: a GNOME shortcut calls ulauncher-toggle instead.
    # Toshy turns Cmd+Space into Shift+Ctrl+Space (see the Toshy overrides), so that combo goes to
    # Ulauncher and the GNOME overview moves to Super+S (also reachable via "Activities").
    gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>s']"
    add_custom_keybinding ulauncher 'Ulauncher' 'ulauncher-toggle' '<Shift><Control>space'

    write_autostart ulauncher.desktop Ulauncher \
        'env GDK_BACKEND=x11 /usr/bin/ulauncher --autostart-method-xdg --hide-window'
    pgrep -f /usr/bin/ulauncher >/dev/null || (setsid ulauncher --hide-window >/dev/null 2>&1 &)
}


# ---------------------------------------------------------------------------
# Step: handy
# ---------------------------------------------------------------------------

step_handy() {
    log 'Handy speech-to-text (Option+Space)'
    if ! is_installed handy; then
        install_github_deb cjpais/Handy "^Handy_.*_$(dpkg --print-architecture)\\.deb\$"
    fi

    # Option+Space is Alt+Space, which GNOME uses for the window menu (still on right-click of the title bar)
    gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"
    add_custom_keybinding handy 'Handy (transcribe)' 'handy --toggle-transcription' '<Alt>space'

    write_autostart Handy.desktop Handy '/usr/bin/handy'
}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: ubuntu.config.sh [step...]   (no step = all, in this order: ${all_steps[*]})"
    echo 'Details: https://github.com/kaspary/sysutils/blob/main/docs/ubuntu.config.md'
}

main() {
    local steps=("$@") step
    (( ${#steps[@]} )) || steps=("${all_steps[@]}")

    for step in "${steps[@]}"; do
        if [[ $step == help || $step == -h || $step == --help ]]; then
            usage
            return 0
        fi
        if ! declare -F "step_$step" >/dev/null; then
            warn "Unknown step '$step'"
            usage
            return 1
        fi
    done

    if [[ ${XDG_CURRENT_DESKTOP:-} != *GNOME* ]]; then
        warn 'This script targets GNOME; shortcuts and extensions may not apply to this desktop.'
    fi

    for step in "${steps[@]}"; do
        "step_$step"
    done

    log 'Done'
    echo 'Manual steps (see docs/ubuntu.config.md):'
    echo '  - Put the Logitech MX Keys Mini in Mac mode: hold Fn+O for 3 seconds.'
    echo '  - Log out and back in (activates the Xremap extension and the Toshy services).'
    echo '  - Use the "en" layout for the Option accents (Super+Space switches br/en).'
}

# Everything runs from here, so bash has read the whole script before any command reads from stdin
main "$@"
