# Contributing to FluxStore

Thank you for your interest in contributing to **FluxStore**. FluxStore is a **fork of [SideStore](https://github.com/SideStore/SideStore)** (itself a community-driven fork of [AltStore](https://github.com/rileytestut/AltStore)). It keeps the same general sideloading architecture—SideStore-style frontend and backend patterns—but ships as **FluxStore** (see `Build.xcconfig` for product name and bundle IDs) and uses the **StikDebug “StikJIT”** integration under `StikJIT/` for **on-device JIT**, instead of the SideJITStreamer-style enabler used upstream.

By contributing to this project, you agree to the Developer's Certificate of Origin in [CERTIFICATE-OF-ORIGIN.md](CERTIFICATE-OF-ORIGIN.md). Any contributions after that file was added are subject to its policy.

Ways to help (including non-code):

-   Upstream [SideStore documentation](https://github.com/SideStore/SideStore-Docs) and issue templates often still apply conceptually; report FluxStore-specific bugs and features on [**Issues**](https://github.com/FluxStore-App/FluxStore/issues).
-   SideStore community support channels remain useful for shared behavior: [Discord](https://discord.gg/sidestore-949183273383395328), [GitHub Discussions](https://github.com/SideStore/SideStore/discussions).

This guide focuses on developer setup. If you are stuck after following it, use whichever support channel your maintainers prefer (some teams still use [this Discord invite](https://discord.gg/RgpFBX3Q3k) for dev chat).

## Requirements

This guide assumes you:

-   are on a Mac
-   have Xcode installed
-   have basic command line knowledge (know how to run commands, cd into a directory)
-   have basic Git knowledge ([GitHub Desktop](https://desktop.github.com) is a great tool for beginners, and greatly simplifies working with Git)
-   have basic Swift/iOS development knowledge

## Setup

1. Fork [**FluxStore-App/FluxStore**](https://github.com/FluxStore-App/FluxStore) on GitHub if you need your own remote; otherwise clone the canonical repo below.
2. Clone with submodules: `git clone --recurse-submodules https://github.com/FluxStore-App/FluxStore.git`

    If you are using GitHub Desktop, refer to
    [this guide](https://docs.github.com/en/desktop/contributing-and-collaborating-using-github-desktop/adding-and-cloning-repositories/cloning-and-forking-repositories-from-github-desktop).

3. Copy `CodeSigning.xcconfig.sample` to `CodeSigning.xcconfig` and fill in the values.
4. **(Development only)** Set `ALTDeviceID` in the app `Info.plist` to your device UDID. Normally the companion server embeds the UDID at install time; in Xcode you must set it yourself or FluxStore may not resign or install for the correct device.
5. Open `AltStore.xcodeproj` in Xcode. The main app scheme is still named **SideStore** for historical reasons; the built product name is **FluxStore**.

Next, make and test your changes. Then, commit and push your changes using git and make a pull request.

## Prebuilt binary information

minimuxer and em_proxy use prebuilt static library binaries built by GitHub Actions to speed up builds and remove the need for Rust to be installed for routine FluxStore work. The em_proxy Xcode target runs `Dependencies/em_proxy/fetch-prebuilt.sh em_proxy` (needs **wget**); CI and `scripts/ci/workflow.py` also run **`scripts/ci/fetch_em_proxy_prebuilt.sh`** before `xcodebuild` so device libraries exist before `em_proxy-swift` compiles.

**AltSign submodule + SwiftPM:** FluxStore links AltSign as a **local Swift package** at `Dependencies/AltSign` (git submodule). Before resolving packages, `make` and CI run `python3 scripts/ci/patch_altsign_package_swift.py`, which adjusts AltSign’s `Package.swift` so Xcode 26 does not hit the bogus `/Package.swift` SwiftPM error. If you open the project without running `make`, run that command once after `git submodule update --init --recursive`. The same script **clones `SideStore/AltSign` into `Dependencies/AltSign`** if the submodule directory is still missing (for example a shallow CI clone without gitlinks), with **`git submodule update --init --recursive` inside that repo** so nested checkouts (`Dependencies/ldid`, `Dependencies/OpenSSL`, etc.) exist—otherwise SwiftPM reports `ldid-core` as empty. Override clone URL/branch with `FLUXSTORE_ALTSIGN_CLONE_URL` / `FLUXSTORE_ALTSIGN_BRANCH` if you fork AltSign.

**If you still see `/Package.swift` or “manifest cannot be accessed” for a different dependency:** a common cause is an Xcode rule that resolves to a **tag or branch that never had a `Package.swift`** (for example `.upToNextMajor(from: "1.0.0")` when SPM was only added in v2.x). Fix the version rule in **Package Dependencies** (or in `project.pbxproj` / the package’s own `Package.swift`) so it pins a revision that actually contains `Package.swift` at the repo root. FluxStore’s AltSign case was different (empty `path: ""` in AltSign’s manifest + local package); the patch above addresses that.

## Building with Xcode

Install cocoapods if required using: `brew install cocoapods`  
If your branch still uses CocoaPods, from the repository root run `pod install`, then build in Xcode. (Many SideStore-derived trees no longer require Pods for the main app; if `Podfile` is absent, skip this.)

## Building an IPA for distribution

If a `Podfile` is present: `brew install cocoapods` and `pod install` from the repo root.

You can then use: `make build fakesign ipa` from the repository root.  
Default configuration is **Release**.  
Debug: `export BUILD_CONFIG=Debug; make build fakesign ipa`  
Alpha/beta: set `export IS_ALPHA=1` or `export IS_BETA=1` before `make`.

The Makefile still names some paths `SideStore.xcarchive` / `SideStore.ipa` for historical compatibility with upstream scripts; Xcode itself builds **FluxStore.app** as the main product. For a self-contained unsigned IPA in CI, use the **Get IPA** GitHub Actions workflow (`.github/workflows/get-ipa.yml`).

```sh
Examples: 

    # cocoapods
    brew install cocoapods
    # perform installation of the pods
    pod install

    # alpha release build
    export IS_ALPHA=1;make build fakesign ipa
    # alpha debug build
    export IS_ALPHA=1;export BUILD_CONFIG=Debug;make build fakesign ipa

    # beta release build
    export IS_BETA=1;make build fakesign ipa
    # beta debug build
    export IS_BETA=1;export BUILD_CONFIG=Debug;make build fakesign ipa

    # stable release build
    make build fakesign ipa
    # stable debug build
    export BUILD_CONFIG=Debug;make build fakesign ipa
```
FluxStore’s default bundle identifiers are defined in `Build.xcconfig` (under the `com.flux` prefix). For command-line builds you can still export `BUNDLE_ID_SUFFIX` when using the Makefile-driven flow:  
```sh
    # stable release build
    export BUNDLE_ID_SUFFIX=XYZ0123456;make build fakesign ipa
    # stable debug build
    export BUNDLE_ID_SUFFIX=XYZ0123456;export BUILD_CONFIG=Debug;make build fakesign ipa
```
When building from Xcode, `BUNDLE_ID_SUFFIX` may follow `DEVELOPMENT_TEAM` depending on your `CodeSigning.xcconfig` overrides (see `CodeSigning.xcconfig.sample`).
  
    

> **Warning**
>
> The binary created will contain paths to Xcode's DerivedData, and if you built minimuxer on your machine, paths to `$HOME/.cargo`. That can include your username. Prefer a clean CI build (for example the **Get IPA** workflow) if you need to share artifacts without leaking local paths.
> 

## StikJIT / local JIT

FluxStore integrates **StikJIT** for on-device JIT enablement (see the `StikJIT/` sources and the main target’s build settings). This replaces the SideJITStreamer-oriented flow from upstream SideStore for local debugging scenarios.

## Developing minimuxer alongside FluxStore

Please see [minimuxer's README](https://github.com/SideStore/minimuxer) for development instructions.
