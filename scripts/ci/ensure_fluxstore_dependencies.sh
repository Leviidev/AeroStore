#!/usr/bin/env bash
# Populate Dependencies/* when git submodules are not recorded in the parent repo (CI shallow clone, missing gitlinks).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${ROOT}"

# Pinned to SideStore/SideStore main (submodule gitlinks). Shallow clones on master/diverged SHAs break ScanDependencies
# (e.g. libimobiledevice reverse_proxy.c). Override any *_REV in CI if you bump .gitmodules.
: "${FLUXSTORE_LIBPLIST_REV:=258d3c24aa05ade06aac4b5dd5148fd04c02893e}"
: "${FLUXSTORE_LIBUSBMUXD_REV:=30e678d4e76a9f4f8a550c34457dab73909bdd92}"
: "${FLUXSTORE_LIBIMOBILEDEVICE_REV:=e7cc53a65b0f975754760032015f58dfbb87e1a0}"
: "${FLUXSTORE_LIBIMOBILEDEVICE_GLUE_REV:=214bafdde6a1434ead87357afe6cb41b32318495}"
: "${FLUXSTORE_MARKDOWN_ATTRIBUTED_STRING_REV:=750e8d5cb455dcc592a9b6d1cacaa19837e7abff}"
: "${FLUXSTORE_ROXAS_REV:=0784711ed9a3a0bdb5cc57bde35d2c621691cf74}"
# SideStore submodule pins (SideStore/SideStore develop); needed for archive + Minimuxer script + synced apps catalog.
: "${FLUXSTORE_MINIMUXER_REV:=e3614068c77fb09945eff363fbc3f9e8abf4c834}"
: "${FLUXSTORE_APPS_V2_JSON_REV:=9724b1c56d9c339ceefe2197abfbc026cd4cc1ff}"

git submodule sync --recursive 2>/dev/null || true
git submodule update --init --recursive 2>/dev/null || true

# $1 = path under ROOT, $2 = git URL, $3 = full commit SHA, $4 = marker file (relative to $1) that must exist
clone_at_rev() {
  local rel="$1" url="$2" rev="$3" marker="$4"
  local abs="${ROOT}/${rel}"
  rev="$(printf '%s' "${rev}" | tr -d '\r')"
  if [[ ! "${rev}" =~ ^[0-9a-fA-F]{40}$ ]]; then
    echo "error: invalid full commit SHA for ${rel} (got '${rev}')" >&2
    exit 1
  fi
  if [[ -f "${abs}/${marker}" || -d "${abs}/${marker}" ]]; then
    return 0
  fi
  echo "ensure_fluxstore_dependencies: cloning ${url} @ ${rev} -> ${rel}" >&2
  rm -rf "${abs}"
  mkdir -p "$(dirname "${abs}")"
  # -n: do not checkout remote HEAD; some runners inherit partial-clone settings and fail reading HEAD's tree during clone.
  git clone -n "${url}" "${abs}"
  if ! git -C "${abs}" checkout -q "${rev}"; then
    git -C "${abs}" fetch -q origin "${rev}"
    git -C "${abs}" checkout -q "${rev}"
  fi
  git -C "${abs}" submodule update --init --recursive 2>/dev/null || true
  if [[ ! -f "${abs}/${marker}" && ! -d "${abs}/${marker}" ]]; then
    echo "error: after clone @ ${rev}, missing ${rel}/${marker}" >&2
    exit 1
  fi
}

[[ -f "${ROOT}/Dependencies/libplist/src/Uid.cpp" ]] \
  || clone_at_rev "Dependencies/libplist" "https://github.com/SideStore/libplist.git" "${FLUXSTORE_LIBPLIST_REV}" "src/Uid.cpp"

[[ -f "${ROOT}/Dependencies/libusbmuxd/src/libusbmuxd.c" ]] \
  || clone_at_rev "Dependencies/libusbmuxd" "https://github.com/libimobiledevice/libusbmuxd.git" "${FLUXSTORE_LIBUSBMUXD_REV}" "src/libusbmuxd.c"

[[ -f "${ROOT}/Dependencies/libimobiledevice/src/idevice.c" ]] \
  || clone_at_rev "Dependencies/libimobiledevice" "https://github.com/SideStore/libimobiledevice.git" "${FLUXSTORE_LIBIMOBILEDEVICE_REV}" "src/idevice.c"

[[ -f "${ROOT}/Dependencies/libimobiledevice-glue/README.md" ]] \
  || clone_at_rev "Dependencies/libimobiledevice-glue" "https://github.com/libimobiledevice/libimobiledevice-glue.git" "${FLUXSTORE_LIBIMOBILEDEVICE_GLUE_REV}" "README.md"

[[ -f "${ROOT}/Dependencies/MarkdownAttributedString/NSAttributedString+Markdown.m" ]] \
  || clone_at_rev "Dependencies/MarkdownAttributedString" "https://github.com/chockenberry/MarkdownAttributedString.git" "${FLUXSTORE_MARKDOWN_ATTRIBUTED_STRING_REV}" "NSAttributedString+Markdown.m"

[[ -d "${ROOT}/Dependencies/Roxas/Roxas.xcodeproj" ]] \
  || clone_at_rev "Dependencies/Roxas" "https://github.com/rileytestut/Roxas.git" "${FLUXSTORE_ROXAS_REV}" "Roxas.xcodeproj"

[[ -f "${ROOT}/Dependencies/minimuxer/Package.swift" ]] \
  || clone_at_rev "Dependencies/minimuxer" "https://github.com/SideStore/minimuxer.git" "${FLUXSTORE_MINIMUXER_REV}" "Package.swift"

[[ -f "${ROOT}/Dependencies/apps-v2.json/README.md" ]] \
  || clone_at_rev "Dependencies/apps-v2.json" "https://github.com/SideStore/apps-v2.json.git" "${FLUXSTORE_APPS_V2_JSON_REV}" "README.md"

echo "FluxStore dependency trees OK (libplist, libusbmuxd, libimobiledevice, glue, MarkdownAttributedString, Roxas, minimuxer, apps-v2.json)."
