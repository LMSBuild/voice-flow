# Voice Flow

**Talk, and it types for you. Under your own name and logo.**

Hold a key, say what you want, let go. Your words appear wherever your cursor is:
email, texts, notes, your CRM, the browser. It's like Wispr Flow, but:

- **Free.** No subscription, no per-seat cost.
- **Private.** The speech engine runs on your own computer. Nothing is uploaded.
- **Yours.** When you install it, it asks for your business name and logo, and that
  becomes the app's name and icon. "Smith Plumbing Flow", not someone else's brand.
- **Spells your words.** Give it your business name, team names, products and
  suburbs, and it gets them right.

Works on Mac (Apple-chip and Intel) and Windows 10/11.

## Download

Go to [**Releases**](../../releases/latest) and download the one for your computer:

- **Mac:** `Voice-Flow-Mac.zip`
- **Windows:** `Voice-Flow-Windows.zip`

## Install

### Mac (about 5 minutes)

1. Double-click the zip to open it, then double-click **Install Voice Flow.command**.
   If your Mac says it can't be opened: open **System Settings → Privacy & Security**,
   scroll down, click **Open Anyway**, and enter your Mac password.
2. Answer three questions: the app's name, your logo (or Skip), and words to always spell right.
3. When the Settings window opens, switch your app **on** in the Accessibility list.
4. In the app's window, choose **Parakeet V3** if it asks for a model (one-off download, about a minute).
5. Click into any text box, hold **Option + Space**, talk, and let go.

### Windows (about 5 minutes)

1. Right-click the zip → **Extract All** → **Extract**.
2. Double-click **Install Voice Flow.bat**. If a blue box says "Windows protected your PC",
   click **More info → Run anyway**.
3. Answer the same three questions.
4. In the app's window, choose **Parakeet V3** if it asks for a model.
5. Click into any text box, hold **Ctrl + Space**, talk, and let go.

Want a different name or logo later? Run the installer again. Your settings and history are kept.

## What's in here

| Folder | What it does |
|---|---|
| `mac/` | The Mac installer. It builds the branded app on your Mac using only tools macOS already has. |
| `windows/` | The Windows installer. It runs the official signed Handy setup, then puts your name and logo on the shortcuts, menu-bar icon and installed-apps list. |
| `shared/` | Starter settings: push-to-talk, the Parakeet V3 model, filler-word removal, and app self-updates turned off so your branding sticks. |
| `scripts/build-release.sh` | Rebuilds both download zips from any Handy release (run on a Mac). |

## Good to know

- **The security prompt on first run** appears because the installer isn't registered with
  Apple or Microsoft. On Windows, the app itself is the official, code-signed Handy build.
- **On Windows**, the open app window and its taskbar icon still show the original Handy icon,
  because that icon is built into the program file. Everywhere else shows yours.
- **History** of what you've said is kept on your own computer only.

## Credits

Built on [Handy](https://github.com/cjpais/Handy) by CJ Pais, the open-source, offline
dictation app (MIT licence, see `LICENSE-Handy.txt`). Voice Flow adds the brand-your-own
installers and starter settings.

Made by [Selr AI](https://www.selrai.com.au).
