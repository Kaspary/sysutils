#!/bin/bash

# Creates ~/.sysutils/sysutilsrc and sources it from ~/.bashrc and ~/.zshrc.
# Other scripts append their shell settings (aliases, PATH, ...) to sysutilsrc.

declare bashrc=$HOME/.bashrc
declare zshrc=$HOME/.zshrc
declare sysutils=$HOME/.sysutils
declare rcline="source ${HOME}/.sysutils/sysutilsrc"

# Create folder sysutils if not exist, and sysutilsrc
mkdir -p "$sysutils"
touch "$sysutils/sysutilsrc"

# Add sysutilsrc in .bashrc and .zshrc if not exists
for rc in "$bashrc" "$zshrc"; do
    if [[ -f $rc ]]; then
        grep -qxF "$rcline" "$rc" || printf "\n%s\n" "$rcline" >> "$rc"
    fi
done

echo "sysutilsrc configured. Open a new terminal to load it."
