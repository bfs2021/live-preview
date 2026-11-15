#!/usr/bin/env bash
# Tests scripts/install-cloudflared.sh with a stubbed machine architecture (UNAME_M).
# Every case runs in dry-run mode, so it needs no network, no root and no installed cloudflared.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/install-cloudflared.sh"
test_version=9.9.9
fails=0

pass() { echo "ok   - $1"; }
fail() { echo "FAIL - $1"; fails=$((fails + 1)); }

expect_url() { # machine package_suffix
  local machine=$1 pkg=$2 out rc expected
  expected="https://github.com/cloudflare/cloudflared/releases/download/$test_version/cloudflared-linux-$pkg.deb"
  out=$(UNAME_M="$machine" CLOUDFLARED_VERSION="$test_version" bash "$script" --dry-run 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "$machine: expected exit 0, got $rc ($out)"
  elif [ "$out" != "$expected" ]; then
    fail "$machine: expected $expected, got $out"
  else
    pass "$machine installs linux-$pkg"
  fi
}

expect_fail() { # machine
  local machine=$1 out rc
  out=$(UNAME_M="$machine" CLOUDFLARED_VERSION="$test_version" bash "$script" --dry-run 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    fail "$machine: expected a non-zero exit"
  elif [ "${out#*"$machine"}" = "$out" ]; then
    fail "$machine: the error does not name the architecture ($out)"
  else
    pass "$machine fails and names the architecture"
  fi
}

expect_url x86_64 amd64
expect_url amd64 amd64
expect_url aarch64 arm64
expect_url arm64 arm64
expect_fail riscv64

if [ "$fails" -ne 0 ]; then
  echo "$fails test(s) failed"
  exit 1
fi
echo "all tests passed"
