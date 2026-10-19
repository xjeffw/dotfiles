#!/usr/bin/env bash
set -euo pipefail

# Give each niri workspace its own wallpaper, using the pool that hyprctl.py
# cycled through for hyprpaper. The Nth workspace of each monitor gets an image
# by position, interleaved across monitors so no two workspaces share one until
# the pool runs out. Needs a running awww-daemon.

pool="${WALLPAPER_POOL:-$HOME/.local/share/wallpapers/active}"
mapfile -t images < <(find -L "$pool" -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)
if ((${#images[@]} == 0)); then
  echo "no images in $pool" >&2
  exit 1
fi

until awww query >/dev/null 2>&1; do sleep 0.2; done

declare -A shown # output -> image currently displayed

update() {
  local output n image
  # "<output> <pool index>" for the active workspace on each output
  while read -r output n; do
    image="${images[n % ${#images[@]}]}"
    [[ ${shown[$output]:-} == "$image" ]] && continue
    if awww img --outputs "$output" --transition-type fade --transition-duration 0.3 "$image"; then
      shown[$output]=$image
    fi
  done < <(niri msg --json workspaces | jq -r '
    (map(.output | select(. != null)) | unique) as $outputs
    | .[] | select(.is_active and .output != null)
    | .output as $output
    | "\($output) \((.idx - 1) * ($outputs | length) + ($outputs | index($output)))"')
}

while read -r _; do
  update
done < <(niri msg --json event-stream |
  jq --unbuffered -c 'select(.WorkspacesChanged or .WorkspaceActivated)')
