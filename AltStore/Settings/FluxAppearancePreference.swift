//
//  FluxAppearancePreference.swift
//  AltStore
//

import UIKit

enum FluxAppearancePreference: Int, CaseIterable
{
    case system = 0
    case light = 1
    case dark = 2

    static let storageKey = "FluxStore.appearancePreference"

    static var current: FluxAppearancePreference
    {
        let raw = UserDefaults.standard.integer(forKey: storageKey)
        return Self(rawValue: raw) ?? .light
    }

    var userInterfaceStyle: UIUserInterfaceStyle
    {
        switch self
        {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    var localizedTitle: String
    {
        switch self
        {
        case .system: return NSLocalizedString("System", comment: "")
        case .light: return NSLocalizedString("Light", comment: "")
        case .dark: return NSLocalizedString("Dark", comment: "")
        }
    }

    func saveAndApply()
    {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
        Self.applyToAllWindows()
        NotificationCenter.default.post(name: .fluxAppearanceDidChange, object: nil)
    }

    static func applyToAllWindows()
    {
        let style = current.userInterfaceStyle
        for case let windowScene as UIWindowScene in UIApplication.shared.connectedScenes
        {
            windowScene.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}

extension Notification.Name
{
    static let fluxAppearanceDidChange = Notification.Name("FluxStore.fluxAppearanceDidChange")
}
