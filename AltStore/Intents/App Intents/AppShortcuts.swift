//
//  AppShortcuts.swift
//  AltStore
//
//  Created by Riley Testut on 8/23/22.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

import AppIntents

@available(iOS 17, *)
struct ShortcutsProvider: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RefreshAllAppsIntent(),
            phrases: [
                "Refresh \(.applicationName)",
                "Refresh \(.applicationName) apps",
                "Refresh my \(.applicationName) apps",
                "Refresh apps with \(.applicationName)",
            ],
            shortTitle: "Refresh All Apps",
            systemImageName: "arrow.triangle.2.circlepath"
        )
        AppShortcut(
            intent: EnableJITIntent(),
            phrases: [
                "Enable JIT for \(\.$app) with \(.applicationName)",
                "Enable JIT for \(\.$app) using \(.applicationName)",
                "Enable JIT for \(\.$app) in \(.applicationName)",
                "\(.applicationName) enable JIT for \(\.$app)",
                "\(.applicationName) enable JIT",
                "Use \(.applicationName) to enable JIT for \(\.$app)",
                "Use \(.applicationName) to enable JIT",
            ],
            shortTitle: "Enable JIT",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: KillProcessIntent(),
            phrases: [
                "Kill \(\.$process) with \(.applicationName)",
                "Kill \(\.$process) using \(.applicationName)",
                "Kill \(\.$process) in \(.applicationName)",
                "\(.applicationName) kill \(\.$process)",
                "\(.applicationName) kill process",
                "Use \(.applicationName) to kill \(\.$process)",
                "Use \(.applicationName) to stop \(\.$process)",
            ],
            shortTitle: "Kill Process",
            systemImageName: "xmark.circle.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .teal
    }
}
