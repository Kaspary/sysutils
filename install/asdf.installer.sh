#!/bin/bash

declare sysutilsrc=$HOME/.sysutils/sysutilsrc;
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;

git clone https://github.com/asdf-vm/asdf.git ~/.asdf;

declare rcline1='. "$HOME/.asdf/asdf.sh"';
declare rcline2='. "$HOME/.asdf/completions/asdf.bash"';
grep -qxF "$rcline1" $sysutilsrc || printf "\n$rcline1\n" >> $sysutilsrc;
grep -qxF "$rcline2" $sysutilsrc || printf "$rcline2\n" >> $sysutilsrc;

source $sysutilsrc;