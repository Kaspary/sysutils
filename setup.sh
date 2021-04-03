#!/bin/bash

# run and manage all actions

# get_confirm_to_install=true


# function help {
# 	echo "
# 		This script is to help on first insall and configure linux programs

# 		-y = to don't request confirmations to installs and configure
# 	"
# }

# function install {
# 	./install.sh 
# }

# while [ ! $# -eq 0 ]
# do
# 	case "$1" in
#     	--help | -h)
#         	echo "This scrip is to test commands"
#             exit
#             ;;
#         -y)
#         	local get_confirm_to_install = false
#             exit
#             ;;
#     esac
#     shift
# done

echo "Create files" &&
mkdir -p ~/.my_configs &&
cp -rv * ~/.my_configs &&
echo "source ~/.my_configs/commands/config" >> ~/.bashrc &&
source ~/.bashrc &&

sudo apt update &&

echo "Uninstall packages"
source  ~/.my_configs/packages/uninstall/apt_packages &&

echo "Install packages"
source ~/.my_configs/packages/install/apt_packages &&
source ~/.my_configs/packages/install/snap_packages &&
source ~/.my_configs/packages/install/wget_packages &&

upgrade &&

# Hidde snap folder from user home
echo "snap"  >> ~/.hidden &&

# Install extension to synchronize vscode configs
codium --install-extension shan.code-settings-sync &&

# Specific to KDE
# Set dark theme
lookandfeeltool -a org.kde.breezedark.desktop