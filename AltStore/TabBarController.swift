//
//  TabBarController.swift
//  AltStore
//
//  Created by Riley Testut on 9/19/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import AltStoreCore

extension TabBarController
{
    private enum Tab: Int, CaseIterable
    {
        case myApps
        case browse
    }
}

final class TabBarController: UITabBarController
{
    private var initialSegue: (identifier: String, sender: Any?)?
    
    private var _viewDidAppear = false
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.importApp(_:)), name: AppDelegate.importAppDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.presentSources(_:)), name: AppDelegate.addSourceDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.exportFiles(_:)), name: AppDelegate.exportCertificateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.openErrorLog(_:)), name: ToastView.openErrorLogNotification, object: nil)
    }
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        self.configureTabBarAppearance()

        // Phase 1: only show My Apps + Browse tabs.
        // Storyboard still contains other tabs for later, but we remove them at runtime for now.
        if let vcs = self.viewControllers, vcs.count >= 4 {
            let browseNavigationController = vcs[2] as! UINavigationController
            browseNavigationController.tabBarItem.title = NSLocalizedString("Browse", comment: "")
            browseNavigationController.tabBarItem.image = UIImage(systemName: "sparkles")

            let myAppsNavigationController = vcs[3] as! UINavigationController
            myAppsNavigationController.tabBarItem.title = NSLocalizedString("My Apps", comment: "")
            myAppsNavigationController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")

            self.viewControllers = [myAppsNavigationController, browseNavigationController]
        }
    }

    private func configureTabBarAppearance()
    {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .altBackground
        appearance.shadowColor = UIColor.fluxCardBorder
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.fluxSecondaryText
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.fluxSecondaryText,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = .altPrimary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.altPrimary,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        self.tabBar.standardAppearance = appearance
        self.tabBar.scrollEdgeAppearance = appearance
        self.tabBar.tintColor = .altPrimary
        self.tabBar.unselectedItemTintColor = .fluxSecondaryText
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        _viewDidAppear = true
        
        if let (identifier, sender) = self.initialSegue
        {
            self.initialSegue = nil
            self.performSegue(withIdentifier: identifier, sender: sender)
        }
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?)
    {
        guard _viewDidAppear else {
            self.initialSegue = (identifier, sender)
            return
        }
        
        super.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension TabBarController
{
    @objc func presentSources(_ sender: Any)
    {
        // Sources tab removed for Phase 1; route deep links to Browse.
        self.selectedIndex = Tab.browse.rawValue
    }
}

private extension TabBarController
{
    @objc func importApp(_ notification: Notification)
    {
        self.selectedIndex = Tab.myApps.rawValue
    }

    @objc func openErrorLog(_ notification: Notification)
    {
        self.presentSettings()
    }
    
    @objc func exportFiles(_ notification: Notification)
    {
        self.presentSettings()
    }

    func presentSettings()
    {
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        guard let settingsRoot = settingsStoryboard.instantiateInitialViewController() else { return }
        settingsRoot.modalPresentationStyle = .formSheet
        self.present(settingsRoot, animated: true)
    }
}
