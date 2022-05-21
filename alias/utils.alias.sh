declare sysutilsrc=$HOME/.sysutils/sysutilsrc;

declare -a commands=(
    "alias upgrade='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'"
);

wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/config/sysutilsrc.config.sh | bash;

for command in "${commands[@]}"; do
    grep -qxF "$command" $sysutilsrc || printf "\n$command\n" >> $sysutilsrc;
done
