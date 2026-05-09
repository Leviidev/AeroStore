<p align="center">
  <img src="AltStore/Resources/Icons.xcassets/AppIcon.appiconset/1024.png" width="128" height="128" alt="FluxStore app icon" />
</p>

# FluxStore

> FluxStore is a **fork of [SideStore](https://github.com/SideStore/SideStore)**—an *untethered, community-driven* alternative app store for non-jailbroken iOS devices—with Flux branding and a different on-device JIT story (see below).

**Repository:** [github.com/FluxStore-App/FluxStore](https://github.com/FluxStore-App/FluxStore)

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://makeapullrequest.com)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/FluxStore-App/FluxStore/get-ipa.yml?branch=main&label=Get%20IPA&logo=github)](https://github.com/FluxStore-App/FluxStore/actions/workflows/get-ipa.yml)
[![Nightly build](https://img.shields.io/github/actions/workflow/status/FluxStore-App/FluxStore/nightly.yml?branch=main&label=Nightly&logo=github)](https://github.com/FluxStore-App/FluxStore/actions/workflows/nightly.yml)
[![PR build](https://img.shields.io/github/actions/workflow/status/FluxStore-App/FluxStore/pr.yml?label=PR%20build&logo=github)](https://github.com/FluxStore-App/FluxStore/actions/workflows/pr.yml)

Clone this repo (including submodules):

```bash
git clone --recurse-submodules https://github.com/FluxStore-App/FluxStore.git
```

Manual unsigned IPA builds: open [Actions → Get IPA (unsigned)](https://github.com/FluxStore-App/FluxStore/actions/workflows/get-ipa.yml) and run **Run workflow**.

In the app, **Settings → Advanced → Bundle ID presets** (with **Customize installed app bundle identifier** enabled) lets you save per-app bundle ID overrides used when sideloading.

Like SideStore, FluxStore is an iOS application that lets you sideload apps using your Apple ID. It resigns apps with your personal development certificate and uses a [specially designed VPN](https://github.com/jkcoxson/em_proxy) so iOS can install them. Background refresh helps keep the usual 7-day development provisioning window from expiring unexpectedly.

## How FluxStore differs from SideStore

| Area | SideStore (upstream) | FluxStore (this fork) |
|------|----------------------|------------------------|
| **Identity** | SideStore product name and assets | **FluxStore** product name and `com.flux`–style bundle identifiers (see `Build.xcconfig`) |
| **JIT / debugging** | Often discussed alongside **SideJITStreamer**-style enablers | Uses the **StikDebug “StikJIT”** component bundled in-repo (`StikJIT/`) to enable JIT **locally on the device** instead of relying on SideJITStreamer |
| **Codebase** | SideStore frontend + backend patterns | Same SideStore-derived app structure; StikJIT replaces the upstream JIT enabler integration for local JIT |

Upstream SideStore remains a community fork of [AltStore](https://github.com/rileytestut/AltStore). FluxStore tracks that lineage and inherits the same AGPLv3 license.

## Requirements

- **Xcode** 26.x (CI and simulator targets in this repo assume current Apple toolchains; use the latest Xcode you can install for your OS.)
- **iOS** 14+ (project constraints may be higher for some SwiftUI or dependency features—check Xcode for the active deployment target.)
- **Rustup** if you build components that compile Rust locally (`brew install rustup`). Prebuilt binaries are used in many flows; see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Project overview

### FluxStore app

The main iOS target (scheme **SideStore** in Xcode, product **FluxStore**) contains most sideloading, download, and update logic, following the SideStore/AltStore architecture.

### EM Proxy

[EM Proxy](https://github.com/jkcoxson/em_proxy) provides untethered installation by combining a privileged VPN helper ([LocalDevVPN](https://github.com/jkcoxson/LocalDevVPN)) with a loopback approach similar in spirit to [Jitterbug](https://github.com/osy/Jitterbug), without requiring a paid Apple developer program tier for basic sideloading workflows.

### Minimuxer

[Minimuxer](https://github.com/SideStore/minimuxer) is a lockdown muxer that can run inside iOS’s sandbox and speaks the usbmuxd-style protocol expected by LocalDevVPN on device.

### StikJIT (local JIT)

This fork wires in **StikJIT** (from the StikDebug ecosystem) so JIT-capable workflows can be driven **on the device** rather than through SideJITStreamer. Implementation lives under `StikJIT/` and is linked from the main app target.

### Roxas

[Roxas](https://github.com/rileytestut/roxas) is Riley Testut’s shared framework from AltStore. FluxStore still depends on it where upstream does; reducing that dependency is a longer-term upstream goal.

## Troubleshooting SwiftPM (`/Package.swift`)

If Xcode or CI reports that **`/Package.swift` cannot be accessed**, two different things are worth checking: (1) a dependency version that resolves **before** that repo had a root `Package.swift` (fix the version rule in Xcode’s Package Dependencies); (2) for **AltSign**, this fork uses the `Dependencies/AltSign` submodule plus a small manifest patch—see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Contributing / build instructions

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Licensing

This project is licensed under the **AGPLv3** license.
