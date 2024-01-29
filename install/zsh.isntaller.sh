#!/bin/bash

# https://github.com/ohmyzsh/ohmyzsh
# https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#oh-my-zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k;

sudo wget -P /usr/local/share/fonts https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf;

# ZSH_THEME="powerlevel10k/powerlevel10k"
# POWERLEVEL10K_MODE="nerdfont-complete"
# Tilix: Open Tilix → Preferences and click on the selected profile under Profiles. Check Custom font under Text Appearance and select MesloLGS NF Regular.


# sudo apt install zsh -y;
# sudo usermod -s /usr/bin/zsh $(whoami);
# echo "zsh version $(zsh --version) installed and set as a defaults";
# sudo apt install zsh-theme-powerlevel9k -y;
# echo "source /usr/share/powerlevel9k/powerlevel9k.zsh-theme" >> ~/.zshrc;
# echo 'powerlevel9k theme installed and set as default';
