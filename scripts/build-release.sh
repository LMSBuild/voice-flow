#!/bin/bash
# Builds the two download zips (Mac + Windows) from an official Handy release.
# Usage: scripts/build-release.sh [handy-version]   e.g. scripts/build-release.sh 0.9.8
# Run on a Mac. Output goes to dist/.
set -euo pipefail
V="${1:-0.9.8}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist"; WORK="$(mktemp -d)"
BASE="https://github.com/cjpais/Handy/releases/download/v$V"
mkdir -p "$OUT"

# Mac: pristine Handy.app for each chip; branding happens on the user's Mac at install time
MAC="$WORK/Voice Flow Setup"; mkdir -p "$MAC/.payload"
for pair in "aarch64:apple-silicon" "x64:intel"; do
  a="${pair%%:*}"; d="${pair##*:}"
  curl -fsSL --max-time 600 -o "$WORK/$a.dmg" "$BASE/Handy_${V}_$a.dmg"
  hdiutil attach -nobrowse -readonly -mountpoint "$WORK/mnt_$a" "$WORK/$a.dmg" >/dev/null
  ditto "$WORK/mnt_$a/Handy.app" "$MAC/.payload/$d/Flow.app"
  hdiutil detach "$WORK/mnt_$a" >/dev/null
done
cp "$ROOT/mac/Install Voice Flow.command" "$ROOT/mac/READ ME FIRST.html" "$MAC/"
cp "$ROOT/shared/settings_store.json" "$ROOT/LICENSE-Handy.txt" "$MAC/.payload/"
chmod +x "$MAC/Install Voice Flow.command"
(cd "$WORK" && ditto -c -k --sequesterRsrc --keepParent "Voice Flow Setup" "$OUT/Voice-Flow-Mac.zip")

# Windows: official signed Handy installers + the branding script
WIN="$WORK/Voice Flow Setup (Windows)"; mkdir -p "$WIN/setup-files"
for a in x64 arm64; do curl -fsSL --max-time 600 -o "$WIN/setup-files/Handy_$a-setup.exe" "$BASE/Handy_${V}_$a-setup.exe"; done
sed 's/\r*$/\r/' "$ROOT/windows/install.ps1" > "$WIN/setup-files/install.ps1"
cp "$ROOT/shared/settings_store.json" "$ROOT/LICENSE-Handy.txt" "$WIN/setup-files/"
cp "$ROOT/windows/Install Voice Flow.bat" "$ROOT/windows/READ ME FIRST.html" "$WIN/"
(cd "$WORK" && rm -f "$OUT/Voice-Flow-Windows.zip" && zip -qry -X "$OUT/Voice-Flow-Windows.zip" "Voice Flow Setup (Windows)")

rm -rf "$WORK"
ls -la "$OUT"
