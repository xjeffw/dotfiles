#!/usr/bin/env bash
set -euo pipefail

# Pin official npm artifacts for every supported host without updating nixpkgs.
# Claude Code ships native binaries, so Nix repackages these rather than compiling it.
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo "Usage: $0 [VERSION]"
  echo "Update flake.nix and flake.lock to the latest npm release (or VERSION)."
  exit 0
fi
if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [VERSION]" >&2
  exit 2
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
for command in curl jq nix python3; do
  if ! command -v "$command" >/dev/null; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

release=${1:-latest}
if [[ $release != latest && ! $release =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid release: $release" >&2
  exit 1
fi
version=$(
  curl --fail --silent --show-error --location --retry 3 \
    "https://registry.npmjs.org/@anthropic-ai/claude-code/$release" |
    jq --exit-status --raw-output '.version | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))'
)

work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT
cp -- "$repo_dir/flake.nix" "$repo_dir/flake.lock" "$work_dir/"

python3 - "$work_dir/flake.nix" "$version" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
version = sys.argv[2]
text = path.read_text()
for platform in ("linux-x64", "linux-arm64", "darwin-arm64"):
    prefix = (
        f"https://registry.npmjs.org/@anthropic-ai/claude-code-{platform}"
        f"/-/claude-code-{platform}-"
    )
    text, count = re.subn(
        re.escape(prefix) + r"[0-9]+\.[0-9]+\.[0-9]+\.tgz",
        prefix + version + ".tgz",
        text,
    )
    if count != 1:
        sys.exit(f"Expected exactly one Claude Code source URL for {platform}; found {count}")
path.write_text(text)
PY

# Generate the lock in a temporary flake. Failed downloads leave both real files intact.
# Outputs are not evaluated by `nix flake update`, so their relative imports aren't needed.
nix flake update --flake "path:$work_dir" \
  claude-code-src-linux-x64 \
  claude-code-src-linux-arm64 \
  claude-code-src-darwin-arm64

cp -- "$work_dir/flake.nix" "$repo_dir/flake.nix"
cp -- "$work_dir/flake.lock" "$repo_dir/flake.lock"
printf 'Pinned Claude Code %s in flake.nix and flake.lock.\n' "$version"
echo 'Apply with: sudo nixos-rebuild switch'
