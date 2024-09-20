#!/bin/bash

declare tmpScript=$HOME/.sysutils/clear_tmp_folder.sh;
declare autostartFile=$HOME/.config/autostart/clear-tmp-folder.desktop;
declare tmpFolder=$HOME/Downloads/tmp/;

touch $tmpScript;
echo "gio trash $tmpFolder;" > $tmpScript;
echo "mkdir $tmpFolder;" >> $tmpScript;
chmod +x $tmpScript;

mkdir -p $HOME/.config/autostart/ && touch $autostartFile;
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

mkdir -p $tmpFolder;