#!/bin/bash

declare sysutilsrc=$HOME/.sysutils/sysutilsrc;
declare script_dir; script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd);

declare -a commands=(
    "alias upgrade='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'"
);

# Use the local copy when running from a clone, otherwise download it
if [[ -f $script_dir/../config/sysutilsrc.config.sh ]]; then
    bash "$script_dir/../config/sysutilsrc.config.sh";
else
    wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;
fi

for command in "${commands[@]}"; do
    grep -qxF "$command" "$sysutilsrc" || printf "\n%s\n" "$command" >> "$sysutilsrc";
done
