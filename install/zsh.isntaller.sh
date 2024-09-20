#!/bin/bash

# https://github.com/ohmyzsh/ohmyzsh
# https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#oh-my-zsh


sudo apt install zsh -y
rm -rf $HOME/.oh-my-zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";

# Tilix: Open Tilix → Preferences and click on the selected profile under Profiles. Check Custom font under Text Appearance and select MesloLGS NF Regular.
sudo curl --output-dir /usr/local/share/fonts/ -O https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Regular.ttf;

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k;
echo "source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" >> ~/.zshrc;
