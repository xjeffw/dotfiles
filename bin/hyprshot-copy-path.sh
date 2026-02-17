#!/usr/bin/env bash
set -euo pipefail

hyprshot $@ -- echo | wl-copy -n
