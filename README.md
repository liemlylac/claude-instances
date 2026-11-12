<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="Claude Instances icon">
</p>

<h1 align="center">Claude Instances</h1>

<p align="center">
  A small macOS app for running several Claude Desktop instances side by side, each signed in to its own account.
</p>

---

## How it works

Claude Desktop is an Electron app. Starting it with `--user-data-dir=<folder>` gives that instance its own data folder, so it has its own sign-in, settings and history. Claude Instances keeps a list of these folders as **profiles**. Pick a profile and press **Play** to open Claude with that folder.

The **Default** profile opens Claude normally, with no extra flag, using its usual data in `~/Library/Application Support/Claude`.

## Features

- **Profiles**: each has a name and a folder. Two are created on first run:
  - **Default**: `~/.claude` (opens Claude normally; cannot be edited or deleted)
  - **Personal**: `~/.claude-instances/personal`
- **Play**: select a profile and press Play, double-click it, or use the row's Play button. A running instance is brought to the front instead.
- **Live status**: running instances are found automatically by reading each Claude process's `--user-data-dir`, so a green dot shows even for instances started elsewhere.
- **Signed-in account**: each profile shows the account it's signed in to, e.g. `Default (John)`, with the email underneath.
- **Safe delete**: type the profile name, press Continue, then confirm. This only removes the profile from the list. Its folder on disk is kept.
- **Menu bar item**: launch any profile from the menu bar.
- **Settings** (⌘,):
  - Language: English, 日本語, 한국어, ไทย, 中文, Tiếng Việt
  - Hide from Dock, Hide from menu bar, Launch at login, Start hidden
  - Path to Claude.app (default `/Applications/Claude.app`)

If both the Dock icon and the menu bar icon are hidden, open the app again from Finder or Launchpad to show the window.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools (Swift 5.9+)
- Claude Desktop

## Build

```bash
./build-app.sh
open "build/Claude Instances.app"
```

The script builds a universal (arm64 and x86_64) release, packages `build/Claude Instances.app` and signs it ad-hoc. Drag it to `/Applications` to install.

For a quick run without packaging, use `swift run`. Launch at login only works from the packaged `.app`.

To regenerate the icon (`Resources/AppIcon.icns`):

```bash
swift scripts/make-icon.swift
```

## Project layout

```
Sources/ClaudeInstances/
  main.swift            app entry point
  AppDelegate.swift     windows, menu bar item, main menu, Dock/menu bar settings
  Profiles.swift        profile model and store, launching, running-instance detection
  AccountReader.swift   reads the signed-in account from a Claude data folder
  AppSettings.swift     user settings and launch at login (SMAppService)
  Localization.swift    strings for all 6 languages
  MainView.swift        profile list, editor and delete confirmation
  SettingsView.swift    settings window
scripts/make-icon.swift draws the app icon
build-app.sh            builds and packages the .app
```

## Notes

- This is an unofficial workaround and may break when Claude Desktop updates.
- The signed-in account is read from Claude's internal cache (`config.json` plus the claude.ai IndexedDB). If that format changes, profiles simply show without an account name.
- `~/Library/Application Support/Claude` can't be used as a profile folder, because it belongs to the normal instance and would clash with its lock.
- All instances share the same "Claude" icon in the Dock.

## License

[MIT](LICENSE)
