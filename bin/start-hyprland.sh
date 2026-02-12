#!/usr/bin/env bash
set -eu

while ! (ssh-add -l | grep -q "$USER"); do
  echo "ssh key must be added before starting hyprland"
  ssh-add || (echo "Failed to add ssh key" && true)
done

(mount | grep /mnt/huge 2>/dev/null) || mount /mnt/huge

set +e
# systemd-cat --identifier=hyprland Hyprland
start-hyprland
systemctl --user stop graphical-session.target
