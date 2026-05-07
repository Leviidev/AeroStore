//
//  NavigationBar.swift
//  AltStore
//
//  Created by Riley Testut on 7/15/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit

import Roxas

class NavigationBarAppearance: UINavigationBarAppearance
{
    // We sometimes need to ignore user interaction so
    // we can tap items underneath the navigation bar.
    var ignoresUserInteraction: Bool = false
    
    override func copy(with zone: NSZone? = nil) -> Any
    {
        let copy = super.copy(with: zone) as! NavigationBarAppearance
        copy.ignoresUserInteraction = self.ignoresUserInteraction
        return copy
    }
}

class NavigationBar: UINavigationBar
{    
    @IBInspectable var automaticallyAdjustsItemPositions: Bool = true
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    private func initialize()
    {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        standardAppearance.backgroundColor = .altBackground
        standardAppearance.shadowColor = UIColor.fluxCardBorder
        
        let edgeAppearance = UINavigationBarAppearance()
        edgeAppearance.configureWithOpaqueBackground()
        edgeAppearance.backgroundColor = .altBackground
        edgeAppearance.shadowColor = UIColor.fluxCardBorder
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        let largeTitleAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        standardAppearance.titleTextAttributes = titleAttrs
        standardAppearance.largeTitleTextAttributes = largeTitleAttrs
        edgeAppearance.titleTextAttributes = titleAttrs
        edgeAppearance.largeTitleTextAttributes = largeTitleAttrs
        standardAppearance.configureWithTintColor(.altPrimary)
        edgeAppearance.configureWithTintColor(.altPrimary)
        
        self.scrollEdgeAppearance = edgeAppearance
        self.standardAppearance = standardAppearance
        self.compactAppearance = standardAppearance
        self.tintColor = .altPrimary
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        if self.automaticallyAdjustsItemPositions
        {
            // We can't easily shift just the back button up, so we shift the entire content view slightly.
            for contentView in self.subviews
            {
                guard NSStringFromClass(type(of: contentView)).contains("ContentView") else { continue }
                contentView.center.y -= 2
            }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        if let appearance = self.topItem?.standardAppearance as? NavigationBarAppearance, appearance.ignoresUserInteraction
        {
            // Ignore touches.
            return nil
        }
        
        return super.hitTest(point, with: event)
    }
}
