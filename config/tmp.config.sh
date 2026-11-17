#!/bin/bash

# Creates ~/Downloads/tmp and empties it (moving the files to the trash) on every login.

declare tmpScript=$HOME/.sysutils/clear_tmp_folder.sh;
declare autostartFile=$HOME/.config/autostart/clear-tmp-folder.desktop;
declare downloads; downloads=$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads");
declare tmpFolder=$downloads/tmp;

mkdir -p "$HOME/.sysutils" "$HOME/.config/autostart" "$tmpFolder";

cat <<SCRIPT > "$tmpScript"
#!/bin/bash
# Move everything inside $tmpFolder to the trash
mkdir -p "$tmpFolder"
find "$tmpFolder" -mindepth 1 -maxdepth 1 -exec gio trash {} +
SCRIPT
chmod +x "$tmpScript";

cat <<DESKTOP > "$autostartFile"
[Desktop Entry]
Type=Application
Exec=$tmpScript
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Clean tmp folder
Name=Clean tmp folder
Comment[en_US]=Move all files in "$tmpFolder" to the trash
Comment=Move all files in "$tmpFolder" to the trash
DESKTOP

echo "$tmpFolder will be emptied on every login.";
