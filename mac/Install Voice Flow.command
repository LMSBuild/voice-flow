#!/bin/bash
# Voice Flow installer — asks for a name, logo and words, then builds a
# branded copy of the dictation app on this Mac (Apple-chip or Intel).
# Built on Handy (MIT licence, github.com/cjpais/Handy) — see .payload/LICENSE-Handy.txt
DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="${FLOW_DEST:-/Applications}"
if [ "$(uname -m)" = "arm64" ]; then SRC="$DIR/.payload/apple-silicon/Flow.app"; else SRC="$DIR/.payload/intel/Flow.app"; fi

ask() { osascript -e "text returned of (display dialog \"$1\" default answer \"$2\" with title \"Voice Flow setup\" buttons {\"Next\"} default button \"Next\")" 2>/dev/null; }
fail() { osascript -e "display dialog \"$1\" with title \"Voice Flow setup\" buttons {\"OK\"} with icon caution" >/dev/null 2>&1; echo "$1"; exit 1; }

# 1. Name
NAME="${FLOW_NAME-$(ask 'What should your voice app be called?

Tip: your business name + Flow, e.g. Smith Plumbing Flow' 'My Flow')}"
NAME="$(printf '%s' "$NAME" | tr -d '/:\\"' | sed 's/^ *//;s/ *$//')"
[ -n "$NAME" ] || NAME="My Flow"

# 2. Logo (optional)
if [ -z "${FLOW_LOGO+x}" ]; then
  LOGO="$(osascript -e 'set b to button returned of (display dialog "Add your logo? It becomes the app icon and the little icon in your menu bar.

A square logo works best (PNG or JPG)." with title "Voice Flow setup" buttons {"Skip", "Choose logo..."} default button "Choose logo...")' -e 'if b is "Skip" then return ""' -e 'POSIX path of (choose file with prompt "Pick your logo" of type {"public.image"})' 2>/dev/null)"
else LOGO="$FLOW_LOGO"; fi

# 3. Words to always spell right (optional)
WORDS="${FLOW_WORDS-$(ask 'Any words it should always spell right? Your business name, team names, products, suburbs.

Separate with commas, or leave blank.' '')}"

echo "Building $NAME..."
TMP="$(mktemp -d)"; APP="$TMP/$NAME.app"
ditto "$SRC" "$APP" || fail "Could not copy the app. Ask whoever sent you this."
PL="$APP/Contents/Info.plist"
SLUG="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"; [ -n "$SLUG" ] || SLUG=flow
plutil -replace CFBundleName -string "$NAME" "$PL"
plutil -replace CFBundleDisplayName -string "$NAME" "$PL" 2>/dev/null || plutil -insert CFBundleDisplayName -string "$NAME" "$PL"
plutil -replace CFBundleIdentifier -string "com.voiceflow.$SLUG" "$PL"

if [ -n "$LOGO" ] && [ -f "$LOGO" ]; then
  L="$TMP/logo.png"
  sips -s format png "$LOGO" --out "$L" >/dev/null 2>&1 || fail "That logo file could not be read. Try a PNG or JPG."
  W=$(sips -g pixelWidth "$L" | awk '/pixelWidth/{print $2}'); H=$(sips -g pixelHeight "$L" | awk '/pixelHeight/{print $2}')
  M=$(( W > H ? W : H ))
  if [ "$(sips -g hasAlpha "$L" | awk '/hasAlpha/{print $2}')" = "yes" ]; then sips -p $M $M "$L" >/dev/null
  else sips -p $M $M --padColor FFFFFF "$L" >/dev/null 2>&1; fi
  IS="$TMP/icon.iconset"; mkdir "$IS"
  for s in 16 32 128 256 512; do
    sips -z $s $s "$L" --out "$IS/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$L" --out "$IS/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$IS" -o "$APP/Contents/Resources/icon.icns" || fail "Could not make the app icon from that logo."
  sips -z 64 64 "$L" --out "$TMP/tray.png" >/dev/null
  for f in handy handy_warning tray_idle tray_idle_dark tray_idle_warning tray_idle_warning_dark tray_recording tray_recording_dark tray_transcribing tray_transcribing_dark; do
    cp "$TMP/tray.png" "$APP/Contents/Resources/resources/$f.png"
  done
fi

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || fail "Could not finish building the app."
osascript -e "quit app \"$NAME\"" 2>/dev/null; sleep 1
rm -rf "$DEST/$NAME.app"
ditto "$APP" "$DEST/$NAME.app" || fail "Could not copy into Applications."
xattr -dr com.apple.quarantine "$DEST/$NAME.app" 2>/dev/null

# Starter settings (only on first install, never overwrites someone's own settings)
SUP="${FLOW_SUPPORT:-$HOME/Library/Application Support/com.pais.handy}"
mkdir -p "$SUP"
if [ ! -f "$SUP/settings_store.json" ]; then
  LIST=""
  IFS=',' read -ra ARR <<< "$WORDS"
  for w in "${ARR[@]}"; do
    w="$(printf '%s' "$w" | tr -d '"\\' | sed 's/^ *//;s/ *$//')"
    [ -n "$w" ] && LIST="$LIST${LIST:+, }\"$w\""
  done
  sed "s/\"custom_words\": \[\]/\"custom_words\": [$LIST]/" "$DIR/.payload/settings_store.json" > "$SUP/settings_store.json"
fi
rm -rf "$TMP"
[ -n "$FLOW_NO_LAUNCH" ] && { echo "Built $DEST/$NAME.app"; exit 0; }

open "$DEST/$NAME.app"
sleep 3
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
osascript -e "display dialog \"$NAME is installed.

Two quick things to finish:

1.  In the Settings window that just opened, switch ON  \\\"$NAME\\\"  (Accessibility list).

2.  In the $NAME window, follow the steps. If it asks which voice model to use, choose  Parakeet V3. It downloads once (about a minute).

Then click into any text box, hold  Option + Space , talk, and let go.\" with title \"$NAME\" buttons {\"Done\"} default button \"Done\"" >/dev/null 2>&1
echo "Done. You can close this window."
