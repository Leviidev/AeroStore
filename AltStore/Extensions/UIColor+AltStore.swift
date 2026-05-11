//
//  UIColor+AltStore.swift
//  AltStore
//
//  Created by Riley Testut on 5/23/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import UIKit

extension UIColor
{
    static let altBackground = UIColor(named: "Background")!
    static let fluxCardBackground = UIColor { traits in
        // Prefer platform-consistent surfaces in light mode.
        // (Our custom dark surface is kept for Flux's look.)
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.14, blue: 0.17, alpha: 1.0)
            : UIColor.white
    }
    static let fluxCardBorder = UIColor { traits in
        // Match iOS separators while keeping a subtle Flux border.
        let base = UIColor.separator
        // Lighter border in light mode looks less "boxed" / AI-card-ish.
        return traits.userInterfaceStyle == .dark ? base.withAlphaComponent(0.32) : base.withAlphaComponent(0.15)
    }
    static let fluxSecondaryText = UIColor { traits in
        // Use dynamic label colors so light mode reads correctly.
        _ = traits
        return UIColor.secondaryLabel
    }
}

extension UIColor
{
    private static let brightnessMaxThreshold = 0.85
    private static let brightnessMinThreshold = 0.35
    
    private static let saturationBrightnessThreshold = 0.5
    
    var adjustedForDisplay: UIColor {
        guard self.isTooBright || self.isTooDark else { return self }
        
        return UIColor { traits in
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            guard self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil) else { return self }
            
            brightness = min(brightness, UIColor.brightnessMaxThreshold)
            
            if traits.userInterfaceStyle == .dark
            {
                // Only raise brightness when in dark mode.
                brightness = max(brightness, UIColor.brightnessMinThreshold)
            }
            
            let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
            return color
        }
    }
    
    var isTooBright: Bool {
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        
        guard self.getHue(nil, saturation: &saturation, brightness: &brightness, alpha: nil) else { return false }
        
        let isTooBright = (brightness >= UIColor.brightnessMaxThreshold && saturation <= UIColor.saturationBrightnessThreshold)
        return isTooBright
    }
    
    var isTooDark: Bool {
        var brightness: CGFloat = 0
        guard self.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil) else { return false }
                
        let isTooDark = brightness <= UIColor.brightnessMinThreshold
        return isTooDark
    }
}
