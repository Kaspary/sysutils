#!/bin/bash

declare sysutilsrc=$HOME/.sysutils/sysutilsrc;
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;

curl -sSL https://install.python-poetry.org | python3 -;
declare rcline='export PATH="/home/lidere/.local/bin:$PATH"';
grep -qxF "$rcline" $sysutilsrc || printf "\n$rcline\n" >> $sysutilsrc;

poetry config virtualenvs.in-project true;
poetry config virtualenvs.prefer-active-python true;
poetry config virtualenvs.path .venv;

source $sysutilsrc;
