#!/bin/bash

# macOS-like keyboard on Ubuntu (GNOME on Wayland), tuned for a Logitech MX Keys Mini in Mac mode.
# Full documentation (what it changes, why, how to revert/update): docs/mac-keyboard.config.md
#
#   - layouts "br" + "English (intl., with AltGr dead keys)"
#   - Toshy (https://github.com/RedBearAK/toshy): Cmd as the main modifier, Mac text editing
#   - Xremap GNOME extension (Toshy needs it on Wayland)
#   - Option + C/E/I/N/`/U: ç and accents through the layout's native dead keys
#   - Cmd+Space   -> Ulauncher  (install/ulauncher.installer.sh)
#   - Option+Space -> Handy     (install/handy.installer.sh)
#
# Optional environment variables:
#   TOSHY_REINSTALL=1   run the Toshy installer even if Toshy is already installed

set -euo pipefail

declare -r toshy_dir=$HOME/.config/toshy
declare -r toshy_config=$toshy_dir/toshy_config.py
declare -r toshy_prefs=$toshy_dir/toshy_user_preferences.sqlite
declare -r xremap_extension=xremap@k0kubun.com

declare -r keybindings_schema=org.gnome.settings-daemon.plugins.media-keys
declare -r keybindings_path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings

# Content of the "user_apps" slice of toshy_config.py. Toshy keeps this slice when it is reinstalled
# or upgraded; this script rewrites the whole slice. Key names: "Alt" = Option, "RC" = Cmd,
# "RAlt" = AltGr of us+altgr-intl.
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

wait_for_dpkg_lock() {
    # Paseo's auto-updater runs dpkg in the background and can hold the lock for minutes
    local waited=0
    while pgrep -x dpkg >/dev/null || pgrep -x apt-get >/dev/null; do
        (( waited == 0 )) && warn 'Another apt/dpkg process is running (Paseo updater?). Waiting for it to finish...'
        sleep 5
        waited=$((waited + 5))
    done
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


configure_layouts() {
    log 'Keyboard layouts: br + English (intl., with AltGr dead keys)'
    # us+altgr-intl keeps ' " ` ~ ^ as normal keys and puts ç / dead accents on AltGr,
    # which is where the Toshy overrides send the Option key.
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br'), ('xkb', 'us+altgr-intl')]"
}

install_xremap_extension() {
    log "GNOME extension $xremap_extension"
    if gnome-extensions info "$xremap_extension" >/dev/null 2>&1; then
        echo 'Already installed'
        gnome-extensions enable "$xremap_extension" 2>/dev/null || true
        return 0
    fi
    echo 'Confirm the dialog that GNOME shows'
    # Call it only once: installing twice in the same session leaves the extension in ERROR until re-login
    gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell \
        --method org.gnome.Shell.Extensions.InstallRemoteExtension "$xremap_extension"
}

install_toshy() {
    log 'Toshy'
    if [[ -f $toshy_config && ${TOSHY_REINSTALL:-0} != 1 ]]; then
        echo 'Already installed (TOSHY_REINSTALL=1 forces the installer)'
        return 0
    fi
    apt_install unzip curl python3

    local dir
    dir=$(mktemp -d)
    curl -fsSL -o "$dir/toshy.zip" https://github.com/RedBearAK/toshy/archive/refs/heads/main.zip
    # unzip (not Python's zipfile) keeps the executable bits the installer depends on
    unzip -q "$dir/toshy.zip" -d "$dir"
    wait_for_dpkg_lock
    (cd "$dir"/[Tt]oshy-main && ./setup_toshy.py install < /dev/tty)
    rm -rf "$dir"
}

apply_toshy_overrides() {
    log 'Toshy overrides (Option accents, Option+Space, Cmd+Space)'
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

    # Turn off Toshy's unicode-based Option special characters (replaced by the slice above)
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
}

configure_shortcuts() {
    log 'GNOME shortcuts'
    # Cmd+Space -> Ulauncher. Ulauncher's own hotkey does not work on Wayland, so a GNOME shortcut
    # runs ulauncher-toggle on Shift+Ctrl+Space (what the Toshy override sends for Cmd+Space).
    # The Toshy installer puts the overview on that combo; it moves to Super+S.
    gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>s']"
    add_custom_keybinding ulauncher 'Ulauncher' 'ulauncher-toggle' '<Shift><Control>space'

    # Option+Space (Alt+Space) -> Handy. GNOME uses it for the window menu, which stays on the
    # right-click of the title bar.
    gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"
    add_custom_keybinding handy 'Handy (transcribe)' 'handy --toggle-transcription' '<Alt>space'

    is_installed ulauncher || warn 'Ulauncher is not installed: run install/ulauncher.installer.sh'
    is_installed handy || warn 'Handy is not installed: run install/handy.installer.sh'
}

main() {
    if [[ ${XDG_CURRENT_DESKTOP:-} != *GNOME* ]]; then
        warn 'This script targets GNOME; shortcuts and extensions may not apply to this desktop.'
    fi

    configure_layouts
    install_xremap_extension
    install_toshy
    apply_toshy_overrides
    configure_shortcuts

    log 'Done'
    echo 'Next:'
    echo '  - Put the MX Keys Mini in Mac mode: hold Fn+O for 3 seconds.'
    echo '  - Log out and back in (activates the Xremap extension and the Toshy services).'
    echo '  - Use the "en" layout for the Option accents (Super+Space switches br/en).'
}

# Everything runs from here, so bash has read the whole script before any command reads from stdin
main "$@"
