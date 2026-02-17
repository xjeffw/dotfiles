#!/usr/bin/env bash
set -euo pipefail

exec emacs --init-directory=~/.config/emacs.elpaca "$@"
