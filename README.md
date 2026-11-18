[commit-shield]: https://img.shields.io/github/last-commit/Kaspary/sysutils?style=for-the-badge&logo=GitHub
[commit-url]: https://github.com/Kaspary/sysutils/commits/main
[linkedin-shield]: https://img.shields.io/badge/-João%20Pedro%20Kaspary-6633cc?style=for-the-badge&logo=Linkedin&colorB=2366c2
[linkedin-url]: https://linkedin.com/in/joao-pedro-kaspary
[github-shield]: https://img.shields.io/github/followers/Kaspary?label=João%20Pedro%20Kaspary&style=for-the-badge&logo=GitHub
[github-url]: https://github.com/Kaspary

[![commit-shield]][commit-url]
[![linkedin-shield]][linkedin-url]
[![GitHub followers][github-shield]][github-url]

# Sysutils
Set of scripts to automate process in Linux systems, especially Ubuntu.
To get the scripts, using `wget` or `curl`.

## Usage
With `wget`
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/<path_to_script> | tr -d '\r' | bash
```

Or using `curl`
```
curl -L https://raw.githubusercontent.com/kaspary/sysutils/main/<path_to_script> | tr -d '\r' | bash
```
Where `<path_to_script>` is the path to script from project root.


## Examples

Runing `sysutilsrc.config.sh` script.
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | tr -d '\r' | bash
```

Runing `utils.alias.sh` script.
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | tr -d '\r' | bash
```

Running `mac-keyboard.config.sh` script (Mac-like keyboard with Toshy: Cmd shortcuts, Option accents,
Cmd+Space for Ulauncher, Option+Space for Handy). See [docs/mac-keyboard.config.md](docs/mac-keyboard.config.md).
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/mac-keyboard.config.sh | tr -d '\r' | bash
```

Running `keepass-gdrive.config.sh` script (KeePassXC with the vault folder synced from Google Drive every 5 minutes).
See [docs/keepass-gdrive.config.md](docs/keepass-gdrive.config.md).
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/keepass-gdrive.config.sh | tr -d '\r' | bash
```

Installing desktop apps: `paseo.installer.sh` (Paseo), `ulauncher.installer.sh` (Ulauncher) and
`handy.installer.sh` (Handy speech-to-text). Their shortcuts come from `mac-keyboard.config.sh`.
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/install/paseo.installer.sh | tr -d '\r' | bash
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/install/ulauncher.installer.sh | tr -d '\r' | bash
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/install/handy.installer.sh | tr -d '\r' | bash
```

## Project Struct

```
sysutils
├── alias
│   └── utils.alias.sh
├── config
│   ├── git.config.sh
│   ├── keepass-gdrive.config.sh
│   ├── mac-keyboard.config.sh
│   ├── sysutilsrc.config.sh
│   └── tmp.config.sh
├── deploy
│   ├── aws.lambda.deploy.sh
│   └── heroku.deploy.sh
├── docs
│   ├── keepass-gdrive.config.md
│   └── mac-keyboard.config.md
├── install
│   ├── asdf.installer.sh
│   ├── docker.installer.sh
│   ├── githubcli.installer.sh
│   ├── handy.installer.sh
│   ├── nvm.installer.sh
│   ├── paseo.installer.sh
│   ├── poetry.installer.sh
│   ├── pyenv.installer.sh
│   ├── ulauncher.installer.sh
│   ├── yarn.installer.sh
│   └── zsh.isntaller.sh
└── README.md
```