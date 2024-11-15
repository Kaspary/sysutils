#!/bin/bash

declare bashrc=$HOME/.bashrc
declare zshrc=$HOME/.zshrc
declare sysutils=$HOME/.sysutils
declare rcline="source ${HOME}/.sysutils/sysutilsrc"

# Create folder sysutils if not exist, and sysutilsrc
mkdir -p $sysutils
touch $sysutils/sysutilsrc

# Add .sysutilsrc in .bashrc if not exists
if [[ -f $bashrc ]]; then
    grep -qxF "$rcline" $bashrc || printf "\n$rcline\n" >> $bashrc
fi

# Add .sysutilsrc in .zshrc if not exists
if [[ -f $zshrc ]]; then
    grep -qxF "$rcline" $zshrc || printf "\n$rcline\n" >> $zshrc
fi

# Source the appropriate shell configuration file
if [[ $SHELL =~ "zsh" && -f $zshrc ]]; then
    source $zshrc
elif [[ -f $bashrc ]]; then
    source $bashrc
fi

asdf plugin-add python;

asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

echo "Configuration added to shell startup files."
