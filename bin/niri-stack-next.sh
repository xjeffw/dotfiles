#!/usr/bin/env bash
set -euo pipefail

# Toggle stacking the next new window below the focused window, in the same
# column, instead of niri's default of opening it as a new column.
#
# usage: niri-stack-next.sh [toggle|wait]

unit=niri-stack-next

# niri opens a new window as a column right of the focused one; moving it
# left consumes it into that column, below the window that had focus.
stack_next_window() {
  local kind rest id floating known=""
  while read -r kind rest; do
    case "$kind" in
      # The stream starts by listing the existing windows.
      known) known=" $rest " ;;
      window)
        read -r id floating <<<"$rest"
        [[ $known == *" $id "* || $floating == true ]] && continue
        niri msg action consume-or-expel-window-left --id "$id"
        exit 0
        ;;
    esac
  done < <(niri msg --json event-stream | jq --unbuffered -r '
    if .WindowsChanged then "known \([.WindowsChanged.windows[].id | tostring] | join(" "))"
    elif .WindowOpenedOrChanged then .WindowOpenedOrChanged.window | "window \(.id) \(.is_floating)"
    else empty end')
}

case "${1:-toggle}" in
  toggle)
    if systemctl --user is-active --quiet "$unit"; then
      systemctl --user stop "$unit"
      notify-send -t 1500 "niri" "Next window: new column"
    else
      # A transient unit so toggling off also stops the event stream.
      systemd-run --user --quiet --collect --unit="$unit" "$(realpath "$0")" wait
      notify-send -t 1500 "niri" "Next window: stacked below"
    fi
    ;;
  wait) stack_next_window ;;
  *)
    echo "usage: $(basename "$0") [toggle|wait]" >&2
    exit 2
    ;;
esac
