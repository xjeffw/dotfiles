#!/usr/bin/env bash
set -euo pipefail

# Profile Emacs startup and generate a flamegraph
# Requires perf and flamegraph (provided by nixpkgs)

OUTPUT="flamegraph.svg"
EMACS_BIN=$(which emacs)
INIT_DIR="$(dirname "$0")"

echo "Profiling Emacs in $INIT_DIR..."

# Record profile data
# -g enables call-graph recording
# -F 99 samples at 99Hz to avoid overhead/syncing with other timers
perf record -F 99 -g -- "$EMACS_BIN" --init-directory "$INIT_DIR"

echo "Generating flamegraph..."

# Process the data
# perf script converts perf.data to readable text
# stackcollapse-perf.pl collapses the stack traces
# flamegraph.pl generates the SVG
perf script | stackcollapse-perf.pl | flamegraph.pl > "$OUTPUT"

echo "Success! Flamegraph saved to $OUTPUT"
