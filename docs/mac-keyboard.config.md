# `config/mac-keyboard.config.sh`

Makes Ubuntu (GNOME on Wayland) behave like a Mac keyboard: `Cmd` as the main modifier, Mac text
editing, accents with `Option`, `Cmd+Space` for the launcher and `Option+Space` for dictation.

Tested on Ubuntu 26.04 / GNOME 50 (Wayland) with a Logitech MX Keys Mini.

```
wget -qO- https://raw.githubusercontent.com/kaspary/sysutils/main/config/mac-keyboard.config.sh | tr -d '\r' | bash
```

Run it from a terminal inside the GNOME session: GNOME asks to confirm the extension install, and the
Toshy installer asks questions and the `sudo` password. The script is idempotent: a rerun re-applies
the settings and skips what is already installed.

After the first run:
1. Put the MX Keys Mini in **Mac mode**: hold `Fn` + `O` for 3 seconds.
2. **Log out and back in** (activates the Xremap extension and the Toshy services).

Related installers (any order, before or after this script):
- `install/ulauncher.installer.sh`: the app opened by `Cmd+Space`.
- `install/handy.installer.sh`: the app toggled by `Option+Space`.

This script sets their shortcuts even when they are not installed yet (it warns); a shortcut to a
missing command just does nothing.

## Shortcuts

| Keys | Action |
|---|---|
| `Cmd` + `C` / `V` / `X` / `Z` / `W` / `T` / `Q` / `Tab`... | as on macOS (Toshy) |
| `Cmd` + `←` / `→`, `Option` + `←` / `→` | start/end of line, previous/next word |
| `Ctrl` + `C` in terminals | SIGINT (`Cmd` + `C` copies) |
| `Cmd` + `Space` | Ulauncher |
| `Option` + `Space` | Handy (start/stop transcription) |
| `Super` + `Space` | switch keyboard layout (`br` / `en`) |
| `Super` + `S` | GNOME overview (also *Activities* / top-left corner) |
| `Option` + `C`, `Option` + `Shift` + `C` | ç, Ç |
| `Option` + `E`, then a vowel | á é í ó ú |
| `Option` + `I`, then a vowel | â ê ô |
| `Option` + `N`, then a vowel | ã õ |
| `Option` + `` ` ``, then a vowel | à |
| `Option` + `U`, then `u` | ü |

On the MX Keys Mini: `Cmd` is the key next to the space bar (`alt`/`cmd`), `Option` the one after
it (`start`/`option`).

## What it changes

### 1. Keyboard layouts

- `org.gnome.desktop.input-sources sources` = `[('xkb', 'br'), ('xkb', 'us+altgr-intl')]`.
- **Why `us+altgr-intl`** ("English (intl., with AltGr dead keys)"): `'`, `"`, `` ` ``, `~`, `^` stay
  normal keys (the plain `us+intl` turns them into dead keys, which gets in the way when coding) and
  `ç` / the dead accents live on `AltGr`. The Toshy overrides map `Option` onto those `AltGr` combos.
- **The Option accents only work with the `en` layout active.**

### 2. Xremap GNOME extension

- `xremap@k0kubun.com`, installed through GNOME Shell's `InstallRemoteExtension` (GNOME shows a
  confirmation dialog). On Wayland, Toshy needs one of its supported extensions to know the focused window.
- Called only once on purpose: installing twice in the same session leaves the extension in `ERROR`
  until you log out.

### 3. Toshy

- [Toshy](https://github.com/RedBearAK/toshy) downloaded from the `main` branch (the way its README
  recommends) and installed with `./setup_toshy.py install`. Skipped if
  `~/.config/toshy/toshy_config.py` exists; `TOSHY_REINSTALL=1` forces it.
- The zip is extracted with `unzip` because the installer depends on the executable bits (Python's
  `zipfile` drops them and the install fails with `Permission denied`).
- What the Toshy installer changes in GNOME by itself: `Super` alone no longer opens the overview, the
  overview moves to `Shift+Ctrl+Space` (moved again in step 5), Nautilus opens in list view.
- Uninstall: `./setup_toshy.py uninstall` from a downloaded copy of the Toshy repo.

### 4. Toshy overrides

Written between the `user_apps` slice marks of `~/.config/toshy/toshy_config.py`. Toshy keeps that
slice when it is reinstalled/upgraded; the script rewrites the whole slice (variable
`toshy_user_apps_slice`), compiles the config and restarts `toshy-config.service`.

| Keys | Sent as | Why |
|---|---|---|
| `Option` + `C` / `Shift` + `C` | `AltGr` + `,` | ç / Ç |
| `Option` + `E` | `AltGr` + `'` | dead acute |
| `Option` + `I` | `AltGr` + `6` | dead circumflex |
| `Option` + `N` | `AltGr` + `Shift` + `` ` `` | dead tilde |
| `Option` + `` ` `` | `AltGr` + `` ` `` | dead grave |
| `Option` + `U` | `AltGr` + `Shift` + `'` | dead diaeresis |
| `Option` + `Space` | unchanged | Handy shortcut; Toshy remaps it in JetBrains IDEs otherwise |
| `Cmd` + `Space` | `Shift` + `Ctrl` + `Space` | Ulauncher shortcut |

Also sets the Toshy preference `optspec_layout = Disabled` in
`~/.config/toshy/toshy_user_preferences.sqlite` (same as tray menu → *Option-key Special Characters*).

- **Why not Toshy's own Option special characters:** they type each character as a unicode code
  (`Ctrl+Shift+U` + hex). Electron apps (Paseo, VS Code...) do not support that, so the code shows up
  as letters, gets deleted and the accent is lost. The layout's native dead keys work in every app.
- **Why the `Cmd+Space` override:** Toshy reads GNOME's `toggle-overview` shortcut live and sends it
  for `Cmd+Space`. Moving the overview to `Super+S` would make `Cmd+Space` open the overview.
- Toshy key names: `RC` = Cmd, `Alt` = Option, `RAlt` = AltGr.

### 5. GNOME shortcuts

| Setting | Value |
|---|---|
| `org.gnome.shell.keybindings toggle-overview` | `['<Super>s']` |
| custom shortcut `ulauncher` | `<Shift><Control>space` → `ulauncher-toggle` |
| `org.gnome.desktop.wm.keybindings activate-window-menu` | `[]` (window menu stays on right-click of the title bar) |
| custom shortcut `handy` | `<Alt>space` → `handy --toggle-transcription` |

Custom shortcuts live under `/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/<id>/`;
`add_custom_keybinding` keeps the other entries of the `custom-keybindings` list. Ulauncher's own
hotkey setting does not work on Wayland, which is why a GNOME shortcut calls `ulauncher-toggle`.

## Reverting

```
gsettings reset org.gnome.desktop.input-sources sources
gsettings reset org.gnome.shell.keybindings toggle-overview
gsettings reset org.gnome.desktop.wm.keybindings activate-window-menu
gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings   # removes ALL custom shortcuts
```
Then, from a downloaded copy of the Toshy repo, `./setup_toshy.py remove-tweaks` (undoes its GNOME
tweaks) and `./setup_toshy.py uninstall`.

## Maintaining

- **Change a remap:** edit `toshy_user_apps_slice` and rerun the script. Keymaps in the slice take
  precedence over Toshy's defaults defined later in the file. Check `journalctl --user -u toshy-config`
  after the restart.
- **Add a shortcut:** `add_custom_keybinding <id> <name> <command> <binding>` in `configure_shortcuts`.
  If the combo goes through Toshy, make sure Toshy does not remap it (add a pass-through like
  `Alt-Space` in the slice).
- Before running on a configured machine, `dconf dump /org/gnome/ > before.dconf` lets you diff what
  changed afterwards.

## Troubleshooting

- **Shortcuts stop working:** `systemctl --user status toshy-config`, `journalctl --user -u toshy-config`.
  Toshy's log is buffered, so lines can show up late (e.g. only when the service stops).
- **MX Keys not remapped:** it disappears from the system when Easy-Switch moves it to another
  computer; Toshy grabs it again on reconnect.
- **Xremap extension in `ERROR`:** `gnome-extensions info xremap@k0kubun.com`; log out and back in.
- **Accent comes out wrong:** check that the `en` layout is active (top bar).
- **`Could not get lock /var/lib/dpkg/lock-frontend`** during the Toshy install: usually Paseo's
  updater; the script waits for it. Never kill dpkg.
