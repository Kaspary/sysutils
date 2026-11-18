#!/bin/bash

# Paseo desktop (https://paseo.sh): latest .deb from GitHub releases, SHA-256 checked.
# After this, Paseo updates itself (it downloads the new .deb and asks for the password).

set -euo pipefail

declare -r repo=getpaseo/paseo
declare -r asset_regex="^Paseo-.*-$(dpkg --print-architecture)\\.deb\$"

wait_for_dpkg_lock() {
    # Paseo's own updater runs dpkg in the background and can hold the lock for minutes
    while pgrep -x dpkg >/dev/null || pgrep -x apt-get >/dev/null; do
        echo 'Waiting for another apt/dpkg process to finish...'
        sleep 5
    done
}

install_github_deb() {
    # install_github_deb <owner/repo> <asset regex>: latest release asset, digest checked, installed with apt
    local repo=$1 pattern=$2 dir name url digest
    dir=$(mktemp -d)
    chmod 755 "$dir"   # lets apt's sandbox user read the file

    read -r name url digest < <(
        curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
        python3 -I -c '
import json, re, sys
pattern = re.compile(sys.argv[1])
for asset in json.load(sys.stdin)["assets"]:
    if pattern.search(asset["name"]):
        print(asset["name"], asset["browser_download_url"], asset.get("digest") or "-")
        break
' "$pattern"
    )
    if [[ -z ${name:-} ]]; then
        echo "No release asset of $repo matches '$pattern'" >&2
        rm -rf "$dir"
        return 1
    fi

    echo "Downloading $name"
    curl -fL --progress-bar -o "$dir/$name" "$url"
    if [[ $digest == sha256:* ]]; then
        echo "${digest#sha256:}  $dir/$name" | sha256sum --check --status \
            || { echo "Checksum mismatch for $name" >&2; rm -rf "$dir"; return 1; }
        echo 'Checksum OK'
    else
        echo "GitHub published no digest for $name; installing without checksum verification" >&2
    fi

    wait_for_dpkg_lock
    sudo apt-get install -y "$dir/$name"
    rm -rf "$dir"
}

main() {
    if dpkg-query -W -f='${Status}' paseo 2>/dev/null | grep -q 'install ok installed'; then
        echo 'Paseo is already installed (it updates itself).'
        return 0
    fi
    echo 'Installing Paseo'
    install_github_deb "$repo" "$asset_regex"
    echo 'Paseo installed. It needs at least one agent CLI (e.g. Claude Code) and recommends gh.'
}

main "$@"
