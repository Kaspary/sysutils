#!/bin/bash

# https://yarnpkg.com/getting-started/install
# Yarn is installed through corepack. Corepack is no longer bundled with Node.js 25+,
# so it is installed with npm. Node.js is installed with asdf when it is missing.

set -euo pipefail

declare script_dir; script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd);
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$HOME/.local/bin:$PATH";

reshim() { if command -v asdf >/dev/null; then asdf reshim nodejs 2>/dev/null || true; fi; }

if ! command -v node >/dev/null; then
    if ! command -v asdf >/dev/null; then
        if [[ -f $script_dir/asdf.installer.sh ]]; then
            bash "$script_dir/asdf.installer.sh";
        else
            wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/install/asdf.installer.sh | bash;
        fi
    fi
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true;
    # Latest LTS version
    version=$(curl -fsSL https://nodejs.org/dist/index.json | python3 -I -c "import json,sys; print(next(x['version'] for x in json.load(sys.stdin) if x['lts']).lstrip('v'))");
    echo "Installing Node.js $version (LTS)";
    asdf install nodejs "$version";
    asdf set -u nodejs "$version";
fi

command -v corepack >/dev/null || { npm install -g corepack; reshim; };
corepack enable;
reshim;
COREPACK_ENABLE_DOWNLOAD_PROMPT=0 yarn --version;
