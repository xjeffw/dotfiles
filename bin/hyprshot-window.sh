#!/usr/bin/env bash
set -euo pipefail

hyprshot -m window -- echo | wl-copy -n
