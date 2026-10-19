#!/usr/bin/env bash
set -euo pipefail

# Take a niri screenshot and copy the saved file's path (instead of the image)
# to the clipboard, like hyprshot-copy-path.sh.
#
# usage: niri-screenshot-copy-path.sh [window|screen|region]

case "${1:-window}" in
  window) action=screenshot-window ;;
  screen) action=screenshot-screen ;;
  region) action=screenshot ;;
  *)
    echo "usage: $(basename "$0") [window|screen|region]" >&2
    exit 2
    ;;
esac

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
path="$dir/screenshot-$(date +%Y-%m-%d-%H%M%S).png"

# niri puts the image on the clipboard before writing the file, then reports
# ScreenshotCaptured. Wait for that event so the path replaces the image.
exec {events}< <(exec niri msg --json event-stream)
events_pid=$!
trap 'kill "$events_pid" 2>/dev/null || true' EXIT
# The stream starts with the current state; once that arrives we're subscribed.
read -r -u "$events" _

niri msg action "$action" --path "$path"

# The region picker waits for a selection and can be cancelled, so give up eventually.
while ((SECONDS < 120)); do
  status=0
  read -r -t 1 -u "$events" line || status=$?
  ((status > 128)) && continue # read timed out
  ((status != 0)) && break     # event stream ended
  case "$line" in
    "{\"ScreenshotCaptured\":{\"path\":\"$path\"}}")
      printf '%s' "$path" | wl-copy
      echo "$path"
      exit 0
      ;;
    '{"ScreenshotCaptured":{"path":null}}')
      echo "screenshot was not saved" >&2
      exit 1
      ;;
  esac
done

echo "no screenshot was saved" >&2
exit 1
