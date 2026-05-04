#!/usr/bin/env bash
# Download libem_proxy-ios.a / libem_proxy-sim.a etc. before xcodebuild (same as em_proxy Xcode "Fetch prebuilt" phase).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EM="${ROOT}/Dependencies/em_proxy"
cd "$EM"
if ! command -v wget >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install wget
  else
    echo "error: wget is required to fetch em_proxy prebuilts" >&2
    exit 1
  fi
fi
chmod +x ./fetch-prebuilt.sh
./fetch-prebuilt.sh em_proxy
test -f libem_proxy-ios.a && test -f libem_proxy-sim.a && test -f em_proxy.h
echo "em_proxy prebuilts OK."
