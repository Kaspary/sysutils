#!/bin/bash

# https://github.com/ohmyzsh/ohmyzsh
# https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#oh-my-zsh

set -euo pipefail

declare script_dir; script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd);
declare zsh_custom=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom};

sudo apt update;
sudo apt install -y curl git zsh fontconfig;

# Oh My Zsh (keeps an existing installation)
if [[ ! -d $HOME/.oh-my-zsh ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended;
fi

# MesloLGS NF font, recommended by powerlevel10k
declare fonts=$HOME/.local/share/fonts;
mkdir -p "$fonts";
for style in Regular Bold Italic "Bold Italic"; do
    curl -fsSL -o "$fonts/MesloLGS NF $style.ttf" \
        "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20${style// /%20}.ttf";
done
fc-cache -f "$fonts";

# Use the font in Tilix, when installed
if command -v tilix >/dev/null && profile=$(gsettings get com.gexperts.Tilix.ProfilesList default 2>/dev/null); then
    profile=${profile//\'/};
    schema="com.gexperts.Tilix.Profile:/com/gexperts/Tilix/profiles/$profile/";
    gsettings set "$schema" use-system-font false;
    gsettings set "$schema" font 'MesloLGS NF 12';
fi

# Powerlevel10k theme
if [[ ! -d $zsh_custom/themes/powerlevel10k ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k";
fi
sed -i 's#^ZSH_THEME=.*#ZSH_THEME="powerlevel10k/powerlevel10k"#' "$HOME/.zshrc";

# Oh My Zsh replaces .zshrc, so add sysutilsrc again
if [[ -f $script_dir/../config/sysutilsrc.config.sh ]]; then
    bash "$script_dir/../config/sysutilsrc.config.sh";
else
    wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;
fi

# Default shell (asks for your password)
[[ $(getent passwd "$USER" | cut -d: -f7) == "$(command -v zsh)" ]] || chsh -s "$(command -v zsh)";

echo "Done. Log out and back in to use zsh; the powerlevel10k wizard runs on the first start (or run 'p10k configure').";
