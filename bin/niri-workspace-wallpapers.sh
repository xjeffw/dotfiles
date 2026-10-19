#!/usr/bin/env bash
set -euo pipefail

# Give each niri workspace its own wallpaper, using the pool that hyprctl.py
# cycled through for hyprpaper. The Nth workspace of each monitor gets an image
# by position, interleaved across monitors so no two workspaces share one until
# the pool runs out. `cycle` moves the focused workspace to the next image in
# the pool and remembers the choice. Needs a running awww-daemon.
#
# usage: niri-workspace-wallpapers.sh [run|cycle]

pool="${WALLPAPER_POOL:-$HOME/.local/share/wallpapers/active}"
# "<output>\t<workspace index>\t<image name>" for each cycled workspace
state="${XDG_STATE_HOME:-$HOME/.local/state}/niri-wallpapers"

mapfile -t images < <(find -L "$pool" -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -printf '%f\n' | LC_ALL=C sort -f)
if ((${#images[@]} == 0)); then
  echo "no images in $pool" >&2
  exit 1
fi

declare -A chosen # "<output> <workspace index>" -> image name

load_state() {
  local output idx name
  chosen=()
  [[ -f $state ]] || return 0
  while IFS=$'\t' read -r output idx name; do
    chosen["$output $idx"]=$name
  done <"$state"
}

save_state() {
  local key
  mkdir -p "$(dirname "$state")"
  for key in "${!chosen[@]}"; do
    printf '%s\t%s\t%s\n' "${key% *}" "${key#* }" "${chosen[$key]}"
  done >"$state"
}

# "<output> <workspace index> <default pool index>" for the active workspace on
# each output, or just the focused workspace if $1 is true.
workspaces() {
  niri msg --json workspaces | jq -r --argjson focused "$1" '
    (map(.output | select(. != null)) | unique) as $outputs
    | .[] | select(.output != null and (if $focused then .is_focused else .is_active end))
    | .output as $output
    | "\($output) \(.idx) \((.idx - 1) * ($outputs | length) + ($outputs | index($output)))"'
}

image_for() { # output idx default-index
  local name=${chosen["$1 $2"]:-}
  if [[ -n $name && -e $pool/$name ]]; then
    echo "$name"
  else
    echo "${images[$3 % ${#images[@]}]}"
  fi
}

show() { # output image-name
  awww img --outputs "$1" --transition-type fade --transition-duration 0.3 "$pool/$2"
}

update() {
  local line output idx n name
  declare -A current=() # output -> image path being displayed
  # ": <output>: <size>, scale: <n>, currently displaying: image: <path>"
  while read -r line; do
    if [[ $line =~ ^:\ ([^:]+):\ .*currently\ displaying:\ image:\ (.*)$ ]]; then
      current[${BASH_REMATCH[1]}]=${BASH_REMATCH[2]}
    fi
  done < <(awww query)

  load_state
  while read -r output idx n; do
    name=$(image_for "$output" "$idx" "$n")
    [[ ${current[$output]:-} == "$(realpath "$pool/$name")" ]] && continue
    show "$output" "$name" || true
  done < <(workspaces false)
}

cycle() {
  local output idx n name i
  load_state
  read -r output idx n < <(workspaces true)
  name=$(image_for "$output" "$idx" "$n")
  for i in "${!images[@]}"; do
    [[ ${images[i]} == "$name" ]] && break
  done
  name=${images[(i + 1) % ${#images[@]}]}
  chosen["$output $idx"]=$name
  save_state
  show "$output" "$name"
}

case "${1:-run}" in
  run)
    until awww query >/dev/null 2>&1; do sleep 0.2; done
    while read -r _; do
      update
    done < <(niri msg --json event-stream |
      jq --unbuffered -c 'select(.WorkspacesChanged or .WorkspaceActivated)')
    ;;
  cycle) cycle ;;
  *)
    echo "usage: $(basename "$0") [run|cycle]" >&2
    exit 2
    ;;
esac
