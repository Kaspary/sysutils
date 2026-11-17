#!/bin/bash

# https://asdf-vm.com/guide/getting-started.html
# Since v0.16 asdf is a single Go binary (the old git clone + asdf.sh setup no longer works).

set -euo pipefail

declare sysutilsrc=$HOME/.sysutils/sysutilsrc;
declare script_dir; script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd);
declare bindir=$HOME/.local/bin;
declare datadir=${ASDF_DATA_DIR:-$HOME/.asdf};

if [[ -f $script_dir/../config/sysutilsrc.config.sh ]]; then
    bash "$script_dir/../config/sysutilsrc.config.sh";
else
    wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash;
fi

case "$(uname -m)" in
    x86_64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    i?86) arch=386 ;;
    *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

version=${ASDF_VERSION:-$(curl -fsSL https://api.github.com/repos/asdf-vm/asdf/releases/latest | grep -Po '"tag_name":\s*"\K[^"]+')};
file="asdf-${version}-linux-${arch}.tar.gz";
url="https://github.com/asdf-vm/asdf/releases/download/${version}/${file}";

echo "Installing asdf ${version}";
tmp=$(mktemp -d);
trap 'rm -rf "$tmp"' EXIT;
curl -fsSL -o "$tmp/$file" "$url";
expected=$(curl -fsSL "$url.md5" | awk '{print $1}');
actual=$(md5sum "$tmp/$file" | awk '{print $1}');
[[ $expected == "$actual" ]] || { echo "Checksum mismatch for $file"; exit 1; };
mkdir -p "$bindir";
tar -xzf "$tmp/$file" -C "$tmp" asdf;
install -m 755 "$tmp/asdf" "$bindir/asdf";

# Remove settings from the old (< v0.16) installation
sed -i '\#\.asdf/asdf\.sh#d; \#\.asdf/completions/asdf\.bash#d' "$sysutilsrc";

# Shell settings: shims in PATH and completions for bash and zsh
mkdir -p "$datadir/completions";
"$bindir/asdf" completion bash > "$datadir/completions/asdf.bash";
"$bindir/asdf" completion zsh > "$datadir/completions/_asdf";

declare -a rclines=(
    'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$HOME/.local/bin:$PATH"'
    'if [ -n "$BASH_VERSION" ]; then . "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/asdf.bash"; fi'
    'if [ -n "$ZSH_VERSION" ]; then fpath=("${ASDF_DATA_DIR:-$HOME/.asdf}/completions" $fpath); autoload -Uz _asdf; (( $+functions[compdef] )) && compdef _asdf asdf; fi'
);
for rcline in "${rclines[@]}"; do
    grep -qxF "$rcline" "$sysutilsrc" || printf "%s\n" "$rcline" >> "$sysutilsrc";
done

export PATH="$datadir/shims:$bindir:$PATH";
asdf plugin add python || true;
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true;

asdf version;
