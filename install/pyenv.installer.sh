# https://github.com/pyenv/pyenv

declare sysutilsrc=$HOME/.sysutils/sysutilsrc;

sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm gettext \
    libncurses5-dev tk-dev tcl-dev blt-dev libgdbm-dev git \
    python-dev python3-dev aria2;

wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;

wget -qO- https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash;

declare rcline='export PYTHON_BUILD_ARIA2_OPTS="-x 10 -k 1M"export PATH="~/.pyenv/bin:$PATH"eval "$(pyenv init --path)"eval "$(pyenv init -)"eval "$(pyenv virtualenv-init -)"';

grep -qxF "$rcline" $sysutilsrc || printf "\n$rcline\n" >> $sysutilsrc;

source $sysutilsrc;