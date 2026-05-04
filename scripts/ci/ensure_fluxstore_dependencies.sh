#!/usr/bin/env bash
# Populate Dependencies/* when git submodules are not recorded in the parent repo (CI shallow clone, missing gitlinks).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${ROOT}"

git submodule sync --recursive 2>/dev/null || true
git submodule update --init --recursive 2>/dev/null || true

# $1 = path under ROOT, $2 = git URL, $3 = branch, $4 = marker file (relative to $1) that must exist
clone_fallback() {
  local rel="$1" url="$2" branch="${3:-master}" marker="$4"
  local abs="${ROOT}/${rel}"
  if [[ -f "${abs}/${marker}" ]]; then
    return 0
  fi
  echo "ensure_fluxstore_dependencies: cloning ${url} (${branch}) -> ${rel}" >&2
  rm -rf "${abs}"
  mkdir -p "$(dirname "${abs}")"
  git clone --depth 1 --branch "${branch}" "${url}" "${abs}"
  if [[ ! -f "${abs}/${marker}" ]]; then
    echo "error: after clone, missing ${rel}/${marker}" >&2
    exit 1
  fi
}

[[ -f "${ROOT}/Dependencies/libplist/src/Uid.cpp" ]] \
  || clone_fallback "Dependencies/libplist" "https://github.com/SideStore/libplist.git" "master" "src/Uid.cpp"

[[ -f "${ROOT}/Dependencies/libusbmuxd/src/libusbmuxd.c" ]] \
  || clone_fallback "Dependencies/libusbmuxd" "https://github.com/libimobiledevice/libusbmuxd.git" "master" "src/libusbmuxd.c"

[[ -f "${ROOT}/Dependencies/libimobiledevice/src/idevice.c" ]] \
  || clone_fallback "Dependencies/libimobiledevice" "https://github.com/SideStore/libimobiledevice.git" "master" "src/idevice.c"

[[ -f "${ROOT}/Dependencies/libimobiledevice-glue/README.md" ]] \
  || clone_fallback "Dependencies/libimobiledevice-glue" "https://github.com/libimobiledevice/libimobiledevice-glue.git" "master" "README.md"

[[ -f "${ROOT}/Dependencies/MarkdownAttributedString/NSAttributedString+Markdown.m" ]] \
  || clone_fallback "Dependencies/MarkdownAttributedString" "https://github.com/chockenberry/MarkdownAttributedString.git" "master" "NSAttributedString+Markdown.m"

[[ -d "${ROOT}/Dependencies/Roxas/Roxas.xcodeproj" ]] \
  || clone_fallback "Dependencies/Roxas" "https://github.com/rileytestut/Roxas.git" "master" "Roxas.xcodeproj/project.pbxproj"

echo "FluxStore dependency trees OK (libplist, libusbmuxd, libimobiledevice, glue, MarkdownAttributedString, Roxas)."
