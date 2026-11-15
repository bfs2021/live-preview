#!/usr/bin/env bash
# Installs cloudflared from the release package that matches the runner architecture.
# Env: CLOUDFLARED_VERSION (release to install), RUNNER_TEMP (where the package is downloaded),
#      UNAME_M (override for tests; defaults to `uname -m`), DRY_RUN=1 or --dry-run (print the package URL, install nothing).
set -euo pipefail
version="${CLOUDFLARED_VERSION:-2026.10.3}"
dry_run="${DRY_RUN:-0}"
[ "${1:-}" = "--dry-run" ] && dry_run=1

# An installed cloudflared already works on any architecture, so keep it (same as the old step).
if [ "$dry_run" = 0 ] && command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is already installed: $(command -v cloudflared)"
  exit 0
fi

machine="${UNAME_M:-$(uname -m)}"
case "$machine" in
  x86_64|amd64) pkg=amd64 ;;
  aarch64|arm64) pkg=arm64 ;;
  *)
    echo "::error::unsupported runner architecture '$machine': cloudflared packages are published for x86_64 (amd64) and aarch64 (arm64) only" >&2
    exit 1
    ;;
esac

url="https://github.com/cloudflare/cloudflared/releases/download/$version/cloudflared-linux-$pkg.deb"
if [ "$dry_run" = 1 ]; then
  echo "$url"
  exit 0
fi

dir="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
mkdir -p "$dir"
deb="$dir/cloudflared.deb"
echo "installing cloudflared $version for $machine from $url"
curl -fsSL -o "$deb" "$url"
sudo dpkg -i "$deb"
