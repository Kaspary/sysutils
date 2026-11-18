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

Running `ubuntu.config.sh` script (Ubuntu desktop with my preferences: Mac-like keyboard with Toshy,
KeePass vault synced from Google Drive, Paseo, Ulauncher and Handy).
Pass step names to run only some of them. See [docs/ubuntu.config.md](docs/ubuntu.config.md).
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/ubuntu.config.sh | tr -d '\r' | bash
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/ubuntu.config.sh | tr -d '\r' | bash -s -- keyboard toshy
```

## Project Struct

```
sysutils
├── alias
│   └── utils.alias.sh
├── config
│   ├── git.config.sh
│   ├── sysutilsrc.config.sh
│   ├── tmp.config.sh
│   └── ubuntu.config.sh
├── deploy
│   ├── aws.lambda.deploy.sh
│   └── heroku.deploy.sh
├── docs
│   └── ubuntu.config.md
├── install
│   ├── asdf.installer.sh
│   ├── docker.installer.sh
│   ├── githubcli.installer.sh
│   ├── nvm.installer.sh
│   ├── poetry.installer.sh
│   ├── pyenv.installer.sh
│   ├── yarn.installer.sh
│   └── zsh.isntaller.sh
└── README.md
```