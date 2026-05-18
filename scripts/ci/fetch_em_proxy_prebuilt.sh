#!/usr/bin/env bash
# Download libem_proxy-ios.a / libem_proxy-sim.a etc. before xcodebuild (same as em_proxy Xcode "Fetch prebuilt" phase).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EM="${ROOT}/Dependencies/em_proxy"
CLONE_URL="${FLUXSTORE_EM_PROXY_CLONE_URL:-https://github.com/SideStore/em_proxy.git}"
# SideStore/em_proxy `master` tip no longer ships fetch-prebuilt.sh + em_proxy.xcodeproj; pin the tree FluxStore expects.
# Bump when you update the Dependencies/em_proxy submodule in this repo (match `git ls-tree HEAD Dependencies/em_proxy`).
DEFAULT_EM_PROXY_REV="816dc73350dd456a24232963db77a3064fd9af8a"
REV="${FLUXSTORE_EM_PROXY_REV:-${DEFAULT_EM_PROXY_REV}}"

ensure_em_proxy_tree() {
  if [[ -f "${EM}/fetch-prebuilt.sh" ]]; then
    return 0
  fi
  echo "Dependencies/em_proxy missing or incomplete; trying git submodule…" >&2
  cd "${ROOT}"
  git submodule sync --recursive || true
  git submodule update --init --recursive "Dependencies/em_proxy" || true
  if [[ -f "${EM}/fetch-prebuilt.sh" ]]; then
    return 0
  fi
  echo "Submodule did not populate em_proxy; cloning ${CLONE_URL} at ${REV}…" >&2
  rm -rf "${EM}"
  mkdir -p "$(dirname "${EM}")"
  git clone --recursive "${CLONE_URL}" "${EM}"
  git -C "${EM}" checkout -q "${REV}"
  git -C "${EM}" submodule update --init --recursive
  if [[ ! -f "${EM}/fetch-prebuilt.sh" ]]; then
    echo "error: em_proxy checkout at ${REV} has no fetch-prebuilt.sh under ${EM}" >&2
    exit 1
  fi
}

ensure_em_proxy_tree
cd "${EM}"

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

# ── Layer 1: Wrap fetch-prebuilt.sh so the Xcode build phase exits early ──────
# The Xcode build phase calls ./fetch-prebuilt.sh under /bin/sh with a restricted
# PATH (no Homebrew), so wget is not found. Replace the script with an idempotent
# wrapper that skips the download when the prebuilts already exist.
FETCH_ORIG="${EM}/fetch-prebuilt.sh.orig"
if [[ ! -f "${FETCH_ORIG}" ]]; then
  cp "${EM}/fetch-prebuilt.sh" "${FETCH_ORIG}"
  cat > "${EM}/fetch-prebuilt.sh" << 'WRAPPER_EOF'
#!/usr/bin/env bash
# Idempotent wrapper – skip download when prebuilts are already present.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "${SCRIPT_DIR}/libem_proxy-ios.a" && \
      -f "${SCRIPT_DIR}/libem_proxy-sim.a" && \
      -f "${SCRIPT_DIR}/em_proxy.h" ]]; then
    echo "em_proxy prebuilts already present – skipping download."
    exit 0
fi
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
exec "${SCRIPT_DIR}/fetch-prebuilt.sh.orig" "$@"
WRAPPER_EOF
  chmod +x "${EM}/fetch-prebuilt.sh"
  echo "Patched em_proxy/fetch-prebuilt.sh to be idempotent in Xcode build phase."
fi

# ── Layer 2: Patch em_proxy.xcodeproj build phase script directly ─────────────
# Belt-and-suspenders: rewrite the PBXShellScriptBuildPhase shellScript inside
# em_proxy.xcodeproj/project.pbxproj to prepend Homebrew PATH and an early-exit
# guard.  This fires even if the fetch-prebuilt.sh wrapper is somehow bypassed.
EM_PBXPROJ="${EM}/em_proxy.xcodeproj/project.pbxproj"
if [[ -f "${EM_PBXPROJ}" ]]; then
  python3 - "${EM_PBXPROJ}" << 'PYEOF'
import sys

path = sys.argv[1]
text = open(path, 'r').read()

# Original shellScript value as stored in the pbxproj
# (\n = script newline, \" = script double-quote, all literals in this string)
ORIG = '"#!bash\\npwd\\nchmod +x ./fetch-prebuilt.sh \\n./fetch-prebuilt.sh em_proxy\\n"'

# Replacement: add Homebrew to PATH and exit early when .a files already exist
NEW = (
    '"#!/bin/bash\\n'
    'export PATH=\\"/opt/homebrew/bin:/usr/local/bin:${PATH}\\"\\n'
    'SRCDIR=\\"${SRCROOT:-$(pwd)}\\"\\n'
    'if [[ -f \\"${SRCDIR}/libem_proxy-ios.a\\" && '
    '-f \\"${SRCDIR}/libem_proxy-sim.a\\" && '
    '-f \\"${SRCDIR}/em_proxy.h\\" ]]; then\\n'
    '    echo \\"em_proxy prebuilts present - skipping Xcode fetch phase.\\"; exit 0\\n'
    'fi\\n'
    'pwd\\n'
    'chmod +x ./fetch-prebuilt.sh\\n'
    './fetch-prebuilt.sh em_proxy\\n"'
)

if ORIG in text:
    text = text.replace(ORIG, NEW, 1)
    open(path, 'w').write(text)
    print(f"Patched em_proxy.xcodeproj build phase: Homebrew PATH + idempotent guard added.")
elif 'em_proxy prebuilts present' in text:
    print("em_proxy.xcodeproj build phase already patched.")
else:
    print(f"WARNING: Could not locate original shellScript in {path}; xcodeproj not patched.", file=sys.stderr)
PYEOF
else
  echo "em_proxy.xcodeproj not found at ${EM_PBXPROJ}; skipping xcodeproj patch." >&2
fi
