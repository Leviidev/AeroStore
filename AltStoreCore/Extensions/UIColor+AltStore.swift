//
//  UIColor+AltStore.swift
//  AltStore
//
//  Created by Riley Testut on 5/9/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit

public extension UIColor
{
    private static let colorBundle = Bundle(for: DatabaseManager.self)
    
    static let altPrimary = UIColor(named: "Primary", in: colorBundle, compatibleWith: nil)!
    static let deltaPrimary = UIColor(named: "DeltaPrimary", in: colorBundle, compatibleWith: nil)
    static let clipPrimary = UIColor(named: "ClipPrimary", in: colorBundle, compatibleWith: nil)
    
    static let refreshRed = UIColor(named: "RefreshRed", in: colorBundle, compatibleWith: nil)!
    static let refreshOrange = UIColor(named: "RefreshOrange", in: colorBundle, compatibleWith: nil)!
    static let refreshYellow = UIColor(named: "RefreshYellow", in: colorBundle, compatibleWith: nil)!
    static let refreshGreen = UIColor(named: "RefreshGreen", in: colorBundle, compatibleWith: nil)!

    // Flux design tokens (phase 1)
    static let fluxSurface = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1.0)
    }

    static let fluxElevatedSurface = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.16, blue: 0.21, alpha: 1.0)
            : UIColor.white
    }

    static let fluxSeparator = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.black.withAlphaComponent(0.08)
    }
}
