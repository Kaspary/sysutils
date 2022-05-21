[commit-shield]: https://img.shields.io/github/last-commit/Kaspary/feedget-nlw-rocketseat?style=for-the-badge&logo=GitHub
[commit-url]: https://github.com/Kaspary/chat-websockets/commits/main
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
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/<path_to_script> | bash
```

Or using `curl`
```
curl -L https://raw.githubusercontent.com/kaspary/sysutils/main/<path_to_script> | bash
```
Where `<path_to_script>` is the path to script from project root.


## Examples

Runing `sysutilsrc.config.sh` script.
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash
```

Runing `utils.alias.sh` script.
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/sysutilsrc.config.sh | bash
```

## Project Struct

```
sysutils
├── alias
│   └── utils.alias.sh
├── config
│   ├── sysutilsrc.config.sh
│   └── tmp.config.sh
├── deploy
│   ├── aws.lambda.deploy.sh
│   └── heroku.deploy.sh
├── install
│   ├── docker.installer.sh
│   ├── nvm.installer.sh
│   └── pyenv.installer.sh
└── README.md
```