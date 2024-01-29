#!/bin/bash

declare tmpScript=$HOME/.sysutils/clear_tmp_folder.sh;
declare autostartFile=$HOME/.config/autostart/clear-tmp-folder.desktop;

touch $tmpScript;
echo "gio trash $HOME/Downloads/tmp/;" > $tmpScript;
echo "mkdir $HOME/Downloads/tmp;" >> $tmpScript;


cat <<EOF > $autostartFile
[Desktop Entry]
Type=Application
Exec=$tmpScript
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Clean tmp folder
Name=Clean tmp folder
Comment[en_US]=Remove all files in "$HOME/Downloads/tmp"
Comment=Remove all files in "$HOME/Downloads/tmp"
EOF