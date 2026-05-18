#!/usr/bin/env python3
"""
Validates that the signing configuration is consistent across:
  - Build.xcconfig  (source of truth for PRODUCT_NAME, DEVELOPMENT_TEAM, ORG_IDENTIFIER)
  - Makefile        (ARCHIVE_APP_DIR, ARCHIVE_EXECUTABLE must match)
  - AltStore/Resources/ReleaseEntitlements.plist (must use correct team / bundle IDs)

Run this before `make fakesign` to catch mismatches early and avoid a
silent-crash IPA caused by signing the wrong binary or using stale entitlements.
"""

import re
import sys
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

ERRORS = []
WARNINGS = []

def error(msg):
    ERRORS.append(f"  ❌  {msg}")

def warn(msg):
    WARNINGS.append(f"  ⚠️   {msg}")

def ok(msg):
    print(f"  ✅  {msg}")

# ------------------------------------------------------------------
# 1. Parse Build.xcconfig
# ------------------------------------------------------------------
def parse_xcconfig(path):
    values = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if line.startswith("//") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        values[key.strip()] = val.strip()
    return values

xcconfig_path = ROOT / "Build.xcconfig"
if not xcconfig_path.exists():
    print(f"ERROR: Build.xcconfig not found at {xcconfig_path}")
    sys.exit(1)

cfg = parse_xcconfig(xcconfig_path)

product_name = cfg.get("PRODUCT_NAME", "")
team_id      = cfg.get("DEVELOPMENT_TEAM", "")
org_id       = cfg.get("ORG_IDENTIFIER", "")

if not product_name:
    error("PRODUCT_NAME is not set in Build.xcconfig")
if not team_id:
    warn("DEVELOPMENT_TEAM is not set in Build.xcconfig (OK for open-source forks)")
if not org_id:
    error("ORG_IDENTIFIER is not set in Build.xcconfig")

expected_bundle_id  = f"{org_id}.{product_name.lower()}" if org_id and product_name else ""
expected_app_group  = f"group.{expected_bundle_id}" if expected_bundle_id else ""
expected_app_id     = f"{team_id}.{expected_bundle_id}" if team_id and expected_bundle_id else ""

print(f"\n📋 Build.xcconfig values:")
print(f"     PRODUCT_NAME      = {product_name!r}")
print(f"     DEVELOPMENT_TEAM  = {team_id!r}")
print(f"     ORG_IDENTIFIER    = {org_id!r}")
print(f"     → expected bundle : {expected_bundle_id!r}")
print(f"     → expected group  : {expected_app_group!r}")
print(f"     → expected app-id : {expected_app_id!r}\n")

# ------------------------------------------------------------------
# 2. Parse Makefile — check ARCHIVE_APP_DIR and ARCHIVE_EXECUTABLE
# ------------------------------------------------------------------
makefile_path = ROOT / "Makefile"
if not makefile_path.exists():
    error(f"Makefile not found at {makefile_path}")
else:
    makefile_text = makefile_path.read_text()

    app_dir_match  = re.search(r"^ARCHIVE_APP_DIR\s*:=\s*(.+)$", makefile_text, re.MULTILINE)
    exec_match     = re.search(r"^ARCHIVE_EXECUTABLE\s*:=\s*(.+)$", makefile_text, re.MULTILINE)

    archive_app_dir  = app_dir_match.group(1).strip()  if app_dir_match  else ""
    archive_exec     = exec_match.group(1).strip()     if exec_match     else ""

    print(f"📋 Makefile values:")
    print(f"     ARCHIVE_APP_DIR    = {archive_app_dir!r}")
    print(f"     ARCHIVE_EXECUTABLE = {archive_exec!r}\n")

    expected_app_dir = f"{product_name}.app"
    if archive_app_dir != expected_app_dir:
        error(
            f"Makefile ARCHIVE_APP_DIR is {archive_app_dir!r} "
            f"but should be {expected_app_dir!r} (PRODUCT_NAME + .app)"
        )
    else:
        ok(f"ARCHIVE_APP_DIR matches PRODUCT_NAME  ({archive_app_dir!r})")

    if archive_exec != product_name:
        error(
            f"Makefile ARCHIVE_EXECUTABLE is {archive_exec!r} "
            f"but should be {product_name!r} (must match PRODUCT_NAME — "
            f"ldid will sign a non-existent file and leave the real binary unsigned!)"
        )
    else:
        ok(f"ARCHIVE_EXECUTABLE matches PRODUCT_NAME ({archive_exec!r})")

# ------------------------------------------------------------------
# 3. Check ReleaseEntitlements.plist
# ------------------------------------------------------------------
ents_path = ROOT / "AltStore/Resources/ReleaseEntitlements.plist"
if not ents_path.exists():
    warn(f"ReleaseEntitlements.plist not found at {ents_path} — skipping entitlements check")
else:
    with ents_path.open("rb") as f:
        ents = plistlib.load(f)

    print(f"📋 ReleaseEntitlements.plist values:")
    for k, v in ents.items():
        print(f"     {k} = {v!r}")
    print()

    app_id_val   = ents.get("application-identifier", "")
    team_id_val  = ents.get("com.apple.developer.team-identifier", "")
    groups_val   = ents.get("com.apple.security.application-groups", [])

    # application-identifier
    if expected_app_id and app_id_val != expected_app_id:
        if "XYZ" in app_id_val or "SideStore" in app_id_val:
            error(
                f"ReleaseEntitlements.plist application-identifier is a placeholder/stale value "
                f"({app_id_val!r}). Expected {expected_app_id!r}."
            )
        else:
            error(
                f"ReleaseEntitlements.plist application-identifier is {app_id_val!r} "
                f"but expected {expected_app_id!r}"
            )
    elif expected_app_id:
        ok(f"application-identifier matches ({app_id_val!r})")

    # team-identifier
    if team_id and team_id_val != team_id:
        if "XYZ" in team_id_val:
            error(
                f"ReleaseEntitlements.plist team-identifier is a placeholder ({team_id_val!r}). "
                f"Expected {team_id!r}."
            )
        else:
            error(
                f"ReleaseEntitlements.plist team-identifier is {team_id_val!r} "
                f"but expected {team_id!r}"
            )
    elif team_id:
        ok(f"team-identifier matches ({team_id_val!r})")

    # app groups
    if expected_app_group:
        if expected_app_group not in groups_val:
            stale = [g for g in groups_val if "SideStore" in g or "XYZ" in g]
            if stale:
                error(
                    f"ReleaseEntitlements.plist app-groups contain stale values {stale!r}. "
                    f"Expected {expected_app_group!r} to be present."
                )
            else:
                error(
                    f"ReleaseEntitlements.plist app-groups {groups_val!r} "
                    f"does not contain expected group {expected_app_group!r}"
                )
        else:
            ok(f"app-groups contains expected group ({expected_app_group!r})")

# ------------------------------------------------------------------
# 4. Summary
# ------------------------------------------------------------------
print()
if WARNINGS:
    for w in WARNINGS:
        print(w)

if ERRORS:
    print(f"\n🚨  Signing config validation FAILED — {len(ERRORS)} error(s):\n")
    for e in ERRORS:
        print(e)
    print(
        "\n  Tip: If ARCHIVE_EXECUTABLE doesn't match PRODUCT_NAME, ldid signs a\n"
        "  non-existent file and the real binary stays unsigned. iOS's amfid daemon\n"
        "  will then kill the app silently on launch with no crash log.\n"
    )
    sys.exit(1)
else:
    print("✅  All signing config checks passed.\n")
