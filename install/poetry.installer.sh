#!/bin/bash

declare sysutilsrc=$HOME/.sysutils/sysutilsrc;

sudo apt update;
sudo apt install python3-pip;

wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh;
source $HOME/.cargo/env;

curl -sSL https://install.python-poetry.org | python3 -;
declare rcline='export PATH="$HOME/.local/bin:$PATH"';
grep -qxF "$rcline" $sysutilsrc || printf "\n$rcline\n" >> $sysutilsrc;

source $sysutilsrc;

poetry config virtualenvs.in-project true;
poetry config virtualenvs.prefer-active-python true;
poetry config virtualenvs.path .venv;
