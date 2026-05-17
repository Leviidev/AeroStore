//
//  AppLaunchCoordinator.swift
//  AltStore
//

import UIKit
import AltStoreCore

/// Single place that installs the main tab interface on the key window.
@MainActor
enum AppLaunchCoordinator {
    private static var didInstallMainInterface = false

    static var isMainInterfaceInstalled: Bool { didInstallMainInterface }

    @MainActor
    static func installMainInterface(animated: Bool = true) {
        guard !didInstallMainInterface else { return }
        guard let window = resolveKeyWindow() else {
            print("⚠️ AppLaunchCoordinator: no key window yet")
            return
        }
        installMainInterface(in: window, animated: animated)
    }

    @MainActor
    static func installMainInterface(in window: UIWindow, animated: Bool) {
        guard !didInstallMainInterface else { return }

        let tabBar = TabBarController.makeMainInterface()
        tabBar.loadViewIfNeeded()
        tabBar.view.setNeedsLayout()
        tabBar.view.layoutIfNeeded()
        tabBar.selectedViewController?.loadViewIfNeeded()

        window.backgroundColor = .systemBackground
        window.tintColor = .altPrimary

        let applyRoot = {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
            FluxAppearancePreference.applyToAllWindows()
        }

        if animated {
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: applyRoot)
        } else {
            applyRoot()
        }

        didInstallMainInterface = true
        print("✅ AppLaunchCoordinator: main interface installed (\(tabBar.viewControllers?.count ?? 0) tabs)")
    }

    @MainActor
    static func resolveKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first
    }

    /// Safety net if storyboard custom classes failed to load and launch never finished.
    @MainActor
    static func installMainInterfaceIfNeeded(reason: String) {
        guard !didInstallMainInterface else { return }
        guard let window = resolveKeyWindow() else { return }
        let root = window.rootViewController
        if root is TabBarController { return }
        print("⚠️ AppLaunchCoordinator fallback (\(reason)): root=\(String(describing: type(of: root)))")
        installMainInterface(in: window, animated: false)
    }
}
