#!/usr/bin/env bash
set -eu

while ! (ssh-add -l | grep -q "$USER"); do
  echo "ssh key must be added before starting niri"
  ssh-add || (echo "Failed to add ssh key" && true)
done

(mount | grep /mnt/huge 2>/dev/null) || mount /mnt/huge

set +e
# niri-session runs niri as a systemd user service and stops
# graphical-session.target when niri exits.
niri-session
