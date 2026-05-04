#!/usr/bin/env python3
"""
SwiftPM on Xcode 26 can fail resolving SideStore/AltSign with:
  the package manifest at '/Package.swift' cannot be accessed

The CAltSign target uses `path: ""` for the package root; use `path: "."` instead.

Expects `Dependencies/AltSign` from git submodules. If that tree is missing (e.g. CI
checkout without submodules), clones SideStore/AltSign from GitHub once.

AltSign itself uses nested submodules (e.g. Dependencies/ldid, Dependencies/OpenSSL);
those must be initialized or targets like `ldid-core` resolve as empty.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ALT_DIR = ROOT / "Dependencies" / "AltSign"
PKG = ALT_DIR / "Package.swift"

ALT_SIGN_URL = os.environ.get(
    "FLUXSTORE_ALTSIGN_CLONE_URL",
    "https://github.com/SideStore/AltSign.git",
)
ALT_SIGN_BRANCH = os.environ.get("FLUXSTORE_ALTSIGN_BRANCH", "master")


def _altsign_git_root() -> bool:
    return (ALT_DIR / ".git").exists()


def _ensure_altsign_tree() -> None:
    if PKG.is_file():
        return
    print(
        f"Missing {PKG}; cloning {ALT_SIGN_URL} (branch {ALT_SIGN_BRANCH})…",
        file=sys.stderr,
    )
    ALT_DIR.parent.mkdir(parents=True, exist_ok=True)
    if ALT_DIR.exists():
        shutil.rmtree(ALT_DIR)
    subprocess.run(
        [
            "git",
            "clone",
            "--depth",
            "1",
            "--branch",
            ALT_SIGN_BRANCH,
            "--recurse-submodules",
            ALT_SIGN_URL,
            str(ALT_DIR),
        ],
        check=True,
    )
    if not PKG.is_file():
        raise RuntimeError(f"clone finished but {PKG} is still missing")


def _init_altsign_nested_submodules() -> None:
    if not _altsign_git_root():
        print(
            f"warning: {ALT_DIR} has no .git; cannot init nested submodules (ldid, OpenSSL)",
            file=sys.stderr,
        )
        return
    subprocess.run(
        ["git", "submodule", "sync", "--recursive"],
        cwd=str(ALT_DIR),
        check=False,
    )
    subprocess.run(
        ["git", "submodule", "update", "--init", "--recursive"],
        cwd=str(ALT_DIR),
        check=True,
    )


def main() -> int:
    try:
        _ensure_altsign_tree()
        _init_altsign_nested_submodules()
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f"error: could not obtain a complete AltSign checkout: {exc}", file=sys.stderr)
        print(
            "hint: from repo root run `git submodule sync --recursive` and "
            "`git submodule update --init --recursive`; inside AltSign run the same.",
            file=sys.stderr,
        )
        return 1

    text = PKG.read_text(encoding="utf-8")
    # AltSign indents with a leading space before `.target(` — match that too.
    pattern = r'(\s*\.target\(\s*\n\s*name:\s*"CAltSign",[\s\S]*?)path:\s*""\s*,'
    new, n = re.subn(pattern, r'\1path: ".",', text, count=1)
    if n == 1:
        PKG.write_text(new, encoding="utf-8")
        print(f"Patched {PKG} (CAltSign path \"\" -> \".\").")
        return 0
    if re.search(
        r'\s*\.target\(\s*\n\s*name:\s*"CAltSign",[\s\S]*?path:\s*"\."\s*,',
        text,
    ):
        print("AltSign CAltSign already uses path: '.'; nothing to do.")
        return 0
    print("error: could not find CAltSign target with path: \"\" to patch", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
