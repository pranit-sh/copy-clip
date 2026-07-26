# Copy Clip

A fast, keyboard-first **clipboard manager for Chrome**. Save snippets, search
them instantly, pin the ones you use most, and paste with a single click.

Built with Flutter Web and packaged as a Chrome Manifest V3 extension.

---

## Features

- 📋 **Tap to copy** — click any clip to put it back on your clipboard.
- 📌 **Pin** — pinned clips stay on top and can be **reordered by drag**.
- 🔎 **Instant search** — filter by title or content as you type.
- 🏷️ **Tags** — organize clips with optional user and auto-detected tags.
- 🗑️ **Clear all** — bulk delete with undo via snackbar.
- 🖱️ **Right-click "Save selection to Copy Clip"** — save from any page.
- ⌨️ **Keyboard first**
    - `⌘/Ctrl + K` — focus search
    - `⌘/Ctrl + E` — new clip
    - `↑ / ↓` — move focus in the list
    - `Enter` — copy the focused clip
    - `Esc` — clear search or filter
    - `⌘/Ctrl + Enter` inside the editor — save

Data is stored locally with `SharedPreferences` (via `chrome.storage` on the
web build). Nothing leaves your browser.

---

## Getting started

```bash
flutter pub get
```

### Run in the browser (fastest dev loop)

```bash
flutter run -d chrome
```

### Build the Chrome extension

```bash
flutter build web --release
```

The extension bundle is at `build/web/`.

### Load it in Chrome

1. Open `chrome://extensions`.
2. Toggle **Developer mode** on (top-right).
3. Click **Load unpacked** and pick the `build/web/` folder.
4. Pin Copy Clip to your toolbar for one-click access.

To pick up code changes, rebuild (`flutter build web --release`) and hit the
reload button on the extension card.

---

## Project structure

```
lib/
  main.dart                    App entry
  models/clip.dart             Clip data model
  helper/clip_note_provider.dart  ChangeNotifier — CRUD + persistence
  components/
    home_screen.dart           Main UI, keyboard shortcuts
    clip_list_item.dart        Row card
    clip_bottom_sheet.dart     Add/edit editor
    search.dart                Search field
  util/theme.dart              Design tokens
  web_bridge*.dart             JS ↔ Dart bridge for context-menu selection

web/
  index.html                   Popup shell
  manifest.json                MV3 extension manifest
  background.js                Service worker: context menu
  popup_bootstrap.js           Forwards stashed selection to Flutter
```

---

Bug reports welcome → https://github.com/pranit-sh/copy-clip/issues
