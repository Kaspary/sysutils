#!/bin/bash

# https://python-poetry.org/docs/#installing-with-the-official-installer

set -euo pipefail

declare sysutilsrc=$HOME/.sysutils/sysutilsrc;
declare script_dir; script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd);

if [[ -f $script_dir/../config/sysutilsrc.config.sh ]]; then
    bash "$script_dir/../config/sysutilsrc.config.sh";
else
    wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;
fi

# The installer needs python3 with venv
if ! python3 -c 'import venv, ensurepip' 2>/dev/null; then
    sudo apt update;
    sudo apt install -y python3 python3-venv;
fi

curl -sSL https://install.python-poetry.org | python3 -;

declare rcline='export PATH="$HOME/.local/bin:$PATH"';
grep -qxF "$rcline" "$sysutilsrc" || printf "%s\n" "$rcline" >> "$sysutilsrc";
export PATH="$HOME/.local/bin:$PATH";

# Create the virtualenv in the project (.venv). Since Poetry 2.0 the active python is used by default.
poetry config virtualenvs.in-project true;

poetry --version;
