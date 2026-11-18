# `config/ubuntu.config.sh`

Sets up an Ubuntu desktop (GNOME on Wayland) with my preferences: Mac-like keyboard and shortcuts,
the KeePass vault synced from Google Drive, and the apps I use (Paseo, Ulauncher, Handy).

Tested on Ubuntu 26.04 / GNOME 50 (Wayland) with a Logitech MX Keys Mini.

## Running

All steps:
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/ubuntu.config.sh | tr -d '\r' | bash
```

Only some steps (any order is accepted, but they run in the order given):
```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/ubuntu.config.sh | tr -d '\r' | bash -s -- keyboard toshy
```

Every step is idempotent: running it again only re-applies the settings, and packages already
installed are skipped (so a rerun needs no `sudo`). Run it from a terminal inside the GNOME session:
some steps open dialogs or the browser, and the Toshy installer asks questions.

After the first run:
1. Put the MX Keys Mini in **Mac mode**: hold `Fn` + `O` for 3 seconds.
2. **Log out and back in** (activates the Xremap extension and the Toshy services).

## Steps

| Step | What it does |
|---|---|
| `keyboard` | Layouts `br` + `us+altgr-intl` |
| `keepass` | KeePassXC, rclone and a 2-way sync of the Drive vault folder every 5 min |
| `paseo` | Paseo desktop app |
| `toshy` | Toshy (macOS shortcuts), Xremap GNOME extension and my Toshy overrides |
| `ulauncher` | Ulauncher opened with `Cmd` + `Space` |
| `handy` | Handy speech-to-text toggled with `Option` + `Space` |

The order matters in one place: `ulauncher` must run **after** `toshy`, because the Toshy installer
sets GNOME's overview shortcut to `Shift+Ctrl+Space`, and `ulauncher` takes that combo.

### `keyboard`

- `org.gnome.desktop.input-sources sources` = `[('xkb', 'br'), ('xkb', 'us+altgr-intl')]`.
- **Why `us+altgr-intl`** ("English (intl., with AltGr dead keys)"): `'`, `"`, `` ` ``, `~`, `^` stay
  normal keys (the plain `us+intl` turns them into dead keys, which gets in the way when coding),
  and `ç` / dead accents live on `AltGr`. Toshy maps the Option key onto those AltGr combos.
- `Super` + `Space` switches between `br` and `en`. **The Option accents only work with `en` active.**

### `keepass`

The vault lives in Google Drive (`KeePass/` folder) and is used as a normal local file, so it works
offline and KeePassXC can save to it safely (a FUSE/GVFS mount of Drive does not).

- Installs `keepassxc`.
- Installs **rclone** from the official binary into `~/.local/bin/rclone` (no `sudo`, newer than the
  Ubuntu package), checked against rclone's `SHA256SUMS`. Updated when a newer version exists.
- Creates the rclone remote `gdrive` (OAuth in the browser) only if it does not exist yet.
  Config and token: `~/.config/rclone/rclone.conf` (mode 600).
- Filter `~/.config/rclone/keepass-filter.txt`: only `*.kdbx` / `*.keyx` are synced. Drive allows
  two files with the same name, which breaks `bisync`; the filter keeps them out (they are not touched).
- Local folder `~/Documents/Keepass` (mode 700).
- First run: `rclone bisync --resync --resync-mode newer` creates the baseline. On a second computer
  with files on both sides, the newest copy of each file wins.
- systemd **user** units in `~/.config/systemd/user/`:
  - `keepass-sync.service`: `rclone bisync gdrive:KeePass ~/Documents/Keepass --resilient --recover
    --conflict-resolve none --conflict-loser num`. If the same vault changed on both sides between
    two syncs, **both copies are kept** (the loser gets a numbered name). Merge them in KeePassXC:
    *Database → Merge from database*.
  - `keepass-sync.timer`: 1 min after login, then every 5 min (`Persistent=true` catches up after sleep).
- `~/.config/keepassxc/keepassxc.ini` `[General]`: `AutoSaveAfterEveryChange=true`,
  `AutoReloadOnChange=true` (changes go to Drive on the next sync; changes coming from Drive reload
  the open vault). Close KeePassXC before this step: it rewrites the file on exit.

Useful commands:
```
systemctl --user start keepass-sync        # sync now
journalctl --user -u keepass-sync          # sync logs
systemctl --user list-timers keepass-sync.timer
```

Variables: `RCLONE_REMOTE`, `KEEPASS_REMOTE_DIR`, `KEEPASS_LOCAL_DIR`, `KEEPASS_SYNC_INTERVAL`
(see the script header).

> **rclone's shared Google client id is being retired during 2026.** When the sync starts failing
> with auth errors, create your own OAuth client id
> ([rclone docs](https://rclone.org/drive/#making-your-own-client-id)) and either run
> `rclone config reconnect gdrive:` after `rclone config update gdrive client_id=... client_secret=...`,
> or delete the remote and rerun the step with `RCLONE_DRIVE_CLIENT_ID` / `RCLONE_DRIVE_CLIENT_SECRET`.

### `paseo`

- Downloads the latest `Paseo-<version>-<arch>.deb` from
  [getpaseo/paseo releases](https://github.com/getpaseo/paseo/releases), checks the SHA-256 digest
  that GitHub publishes for the asset, and installs it with `apt` (pulls the dependencies).
- Skipped when already installed: **Paseo updates itself** (it downloads the new `.deb` and asks for
  the password). While that update runs it holds the dpkg lock; the script waits for it
  (`wait_for_dpkg_lock`) instead of failing.

### `toshy`

[Toshy](https://github.com/RedBearAK/toshy) makes the keyboard behave like macOS: `Cmd` is the main
modifier (`Cmd+C/V/X/Z/W/T/Q/Tab`...), `Cmd/Option + arrows` move by line/word, and in terminals
`Ctrl+C` stays SIGINT while `Cmd+C` copies.

- Installs the GNOME extension **Xremap** (`xremap@k0kubun.com`): on Wayland, Toshy needs it to know
  the focused window. GNOME shows a confirmation dialog. It is called only once on purpose:
  installing twice in the same session leaves the extension in `ERROR` until you log out.
- Downloads Toshy from the `main` branch (the way its README recommends) and runs
  `./setup_toshy.py install`. The zip is extracted with `unzip` because the installer depends on the
  executable bits (Python's `zipfile` drops them). Skipped if `~/.config/toshy/toshy_config.py`
  exists; `TOSHY_REINSTALL=1` forces it.
- What the Toshy installer itself changes in GNOME: `Super` alone no longer opens the overview, the
  overview moves to `Shift+Ctrl+Space`, and Nautilus opens in list view.
- **My overrides**, written between the `user_apps` slice marks of `~/.config/toshy/toshy_config.py`
  (Toshy keeps that slice when it is reinstalled/upgraded; the script rewrites the whole slice):

  | Keys | Result | How |
  |---|---|---|
  | `Option` + `C` / `Option` + `Shift` + `C` | ç / Ç | `AltGr` + `,` |
  | `Option` + `E`, vowel | á é í ó ú | dead acute (`AltGr` + `'`) |
  | `Option` + `I`, vowel | â ê ô | dead circumflex (`AltGr` + `6`) |
  | `Option` + `N`, vowel | ã õ | dead tilde (`AltGr` + `Shift` + `` ` ``) |
  | `Option` + `` ` ``, vowel | à | dead grave (`AltGr` + `` ` ``) |
  | `Option` + `U`, `u` | ü | dead diaeresis (`AltGr` + `Shift` + `'`) |
  | `Option` + `Space` | passes through untouched | Handy shortcut (Toshy remaps it in JetBrains otherwise) |
  | `Cmd` + `Space` | `Shift` + `Ctrl` + `Space` | Ulauncher shortcut |

- Toshy preference `optspec_layout = Disabled` (in `~/.config/toshy/toshy_user_preferences.sqlite`).
  Toshy's own "Option-key special characters" types each accent as a unicode code (`Ctrl+Shift+U`),
  which shows garbage and loses the accent in Electron apps (Paseo, VS Code...). The overrides above
  use the layout's **native** dead keys instead, which work everywhere.
- **Why the `Cmd+Space` override:** Toshy reads GNOME's `toggle-overview` shortcut live and sends it
  for `Cmd+Space`. Without the override, moving the overview to `Super+S` would make `Cmd+Space`
  open the overview instead of Ulauncher.
- In Toshy's key names: `RC` = Cmd, `Alt` = Option, `RAlt` = AltGr.

Uninstall Toshy: `./setup_toshy.py uninstall` from a downloaded copy of its repo.

### `ulauncher`

- Installs `ulauncher` from `ppa:agornostal/ulauncher`.
- Ulauncher's own hotkey does not work on Wayland, so a GNOME custom shortcut runs `ulauncher-toggle`:
  `Shift+Ctrl+Space` → `ulauncher-toggle` (what Toshy sends for `Cmd+Space`).
- Moves the GNOME overview to `Super+S` (`org.gnome.shell.keybindings toggle-overview`). The overview
  is also reachable through *Activities* / the top-left corner.
- Autostart: `~/.config/autostart/ulauncher.desktop` (only created if missing).

### `handy`

- Downloads the latest `Handy_<version>_<arch>.deb` from
  [cjpais/Handy releases](https://github.com/cjpais/Handy/releases) (SHA-256 checked) if not installed.
- Frees `Alt+Space` (`Option+Space`) from GNOME's window menu
  (`org.gnome.desktop.wm.keybindings activate-window-menu = []`; the menu stays on right-click of the
  title bar) and binds it to `handy --toggle-transcription`: first press records, second press
  transcribes. Handy's own shortcut (`Ctrl+Alt+Space`) keeps working.
- Autostart: `~/.config/autostart/Handy.desktop` (only created if missing).

## Shortcut summary

| Keys | Action |
|---|---|
| `Cmd` + `Space` | Ulauncher |
| `Option` + `Space` | Handy (start/stop transcription) |
| `Super` + `Space` | Switch keyboard layout (`br` / `en`) |
| `Super` + `S` | GNOME overview |
| `Option` + `C` / `E` / `I` / `N` / `` ` `` / `U` | ç and accents (layout `en`) |

## Maintaining

- **Add a step:** write a `step_<name>` function, add `<name>` to `all_steps` (in the right order),
  and document it here. `main` validates step names against the existing functions.
- **Add a GNOME shortcut:** `add_custom_keybinding <id> <name> <command> <binding>`; it keeps the other
  custom shortcuts in `custom-keybindings`.
- **Install a `.deb` from GitHub releases:** `install_github_deb <owner/repo> <asset regex>`.
- **Change a Toshy remap:** edit `toshy_user_apps_slice` in the script and rerun `toshy`. Keymaps in
  the slice take precedence over Toshy's defaults defined later in the file. The script compiles the
  config before restarting Toshy; still check `journalctl --user -u toshy-config` afterwards.
- **Check what the script would overwrite** before running it on an already configured machine:
  `dconf dump /org/gnome/ > before.dconf` and compare with `diff before.dconf <(dconf dump /org/gnome/)`.

## Troubleshooting

- **`Could not get lock /var/lib/dpkg/lock-frontend`**: usually Paseo's updater installing a new
  version. Let it finish (it may sit on `update-mime-database` for minutes on a slow disk); never kill dpkg.
- **Toshy shortcuts stop working**: `systemctl --user status toshy-config` and
  `journalctl --user -u toshy-config`. Its log is buffered, so lines can show up late (e.g. only
  when the service stops). The MX Keys disappears when Easy-Switch moves it to another computer;
  Toshy grabs it again on reconnect.
- **Xremap extension in `ERROR`**: `gnome-extensions info xremap@k0kubun.com`; log out and back in.
- **Accent comes out wrong**: check that the `en` layout is active (top bar).
