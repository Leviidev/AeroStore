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
    enum Tab: Int, CaseIterable
    {
        case browse
        case myApps
        case notifications
        case settings
    }
}

final class TabBarController: UITabBarController
{
    private var initialSegue: (identifier: String, sender: Any?)?
    
    private var _viewDidAppear = false

    private let floatingTabBarBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private var floatingTabBarBackgroundConstraints: [NSLayoutConstraint] = []
    
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

        // Browse, My Apps, Notifications, Settings.
        if let vcs = self.viewControllers, vcs.count >= 4 {
            // Find the correct view controllers by their storyboard identifiers or types
            var myAppsNavController: UINavigationController?
            var browseNavController: UINavigationController?
            
            // Find My Apps navigation controller (should be the one with MyAppsViewController)
            for vc in vcs {
                if let nav = vc as? UINavigationController {
                    if nav.viewControllers.contains(where: { $0 is MyAppsViewController }) {
                        myAppsNavController = nav
                    } else if nav.viewControllers.contains(where: { $0 is FeaturedViewController }) {
                        browseNavController = nav
                    }
                }
            }
            
            // Use found controllers or fall back to index-based access
            let browseNavigationController = browseNavController ?? vcs[0] as! UINavigationController
            let myAppsNavigationController = myAppsNavController ?? vcs[1] as! UINavigationController
            
            browseNavigationController.tabBarItem.title = NSLocalizedString("Browse", comment: "")
            browseNavigationController.tabBarItem.image = UIImage(systemName: "square.grid.3x3.fill")

            myAppsNavigationController.tabBarItem.title = NSLocalizedString("My Apps", comment: "")
            myAppsNavigationController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let featured = storyboard.instantiateViewController(withIdentifier: "featuredViewController") as! FeaturedViewController
            featured.navigationItem.largeTitleDisplayMode = .always

            let addCatalogAction = UIAction { [weak featured] _ in
                guard let nav = featured?.navigationController else { return }
                let add = FluxAddCatalogViewController()
                let sheet = UINavigationController(rootViewController: add)
                sheet.modalPresentationStyle = .formSheet
                sheet.navigationBar.prefersLargeTitles = false
                nav.present(sheet, animated: true)
            }
            // Avoid UIBarButtonItem initializers whose signatures differ across Xcode/iOS SDKs.
            let addHost = UIButton(type: .system)
            addHost.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            addHost.addAction(addCatalogAction, for: .touchUpInside)
            addHost.accessibilityLabel = NSLocalizedString("Add catalog", comment: "")
            featured.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addHost)

            browseNavigationController.setViewControllers([featured], animated: false)

            // Tools tab
            let toolsViewController = FluxToolsViewController()
            let toolsNavigationController = UINavigationController(rootViewController: toolsViewController)
            toolsNavigationController.navigationBar.prefersLargeTitles = true
            toolsNavigationController.tabBarItem.title = NSLocalizedString("Tools", comment: "")
            toolsNavigationController.tabBarItem.image = UIImage(systemName: "wrench.and.screwdriver.fill")

            let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
            // Settings.storyboard's initial VC is ForwardingNavigationController (nav root), not SettingsViewController.
            let settingsNavigationController = settingsStoryboard.instantiateInitialViewController() as! UINavigationController
            settingsNavigationController.navigationBar.prefersLargeTitles = true
            settingsNavigationController.tabBarItem.title = NSLocalizedString("Settings", comment: "")
            settingsNavigationController.tabBarItem.image = UIImage(systemName: "gearshape.fill")

            self.viewControllers = [
                browseNavigationController,
                myAppsNavigationController,
                toolsNavigationController,
                settingsNavigationController,
            ]
        }
    }

    private func configureTabBarAppearance()
    {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
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

        // Hide black bar completely on iOS 26+ with new bottom menu UI
        if #available(iOS 26.0, *) {
            self.tabBar.isTranslucent = true
            self.tabBar.backgroundImage = UIImage()
            self.tabBar.shadowImage = UIImage()
            self.tabBar.backgroundColor = .clear
            self.tabBar.barTintColor = .clear
            
            // Remove the floating background entirely on iOS 26+
            floatingTabBarBackgroundView.isHidden = true
            return
        }

        // Floating rounded "pill" background for older iOS versions
        self.tabBar.isTranslucent = true
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()

        floatingTabBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        floatingTabBarBackgroundView.isUserInteractionEnabled = false
        floatingTabBarBackgroundView.clipsToBounds = false
        floatingTabBarBackgroundView.layer.cornerRadius = 24
        floatingTabBarBackgroundView.layer.cornerCurve = .continuous
        floatingTabBarBackgroundView.layer.shadowColor = UIColor.black.cgColor
        floatingTabBarBackgroundView.layer.shadowOpacity = 0.10
        floatingTabBarBackgroundView.layer.shadowRadius = 18
        floatingTabBarBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 6)
        self.applyFloatingTabBarVisualStyle()

        self.tabBar.insertSubview(floatingTabBarBackgroundView, at: 0)
        self.updateFloatingTabBarConstraintsIfNeeded()
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        self.updateFloatingTabBarConstraintsIfNeeded()
        floatingTabBarBackgroundView.layer.shadowPath = UIBezierPath(
            roundedRect: floatingTabBarBackgroundView.bounds,
            cornerRadius: floatingTabBarBackgroundView.layer.cornerRadius
        ).cgPath
    }

    private func updateFloatingTabBarConstraintsIfNeeded()
    {
        guard floatingTabBarBackgroundView.superview === self.tabBar else { return }

        NSLayoutConstraint.deactivate(floatingTabBarBackgroundConstraints)
        floatingTabBarBackgroundConstraints.removeAll()

        let guide = self.tabBar.safeAreaLayoutGuide
        /// iOS 26+ shows the detached “floating” pill cleanly; older systems leave awkward empty strips
        /// beside/below it, so we fill the tab bar’s full bounds like a classic bar.
        if #available(iOS 26.0, *)
        {
            let sideInset: CGFloat = self.traitCollection.userInterfaceIdiom == .pad ? 32 : 24
            let height: CGFloat = 58
            let bottomPadding: CGFloat = 12
            floatingTabBarBackgroundConstraints = [
                floatingTabBarBackgroundView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: sideInset),
                floatingTabBarBackgroundView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -sideInset),
                floatingTabBarBackgroundView.heightAnchor.constraint(equalToConstant: height),
                floatingTabBarBackgroundView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -bottomPadding),
            ]
            let pillRadius = height / 2
            floatingTabBarBackgroundView.layer.cornerRadius = pillRadius
            floatingTabBarBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            floatingTabBarBackgroundView.layer.masksToBounds = false
        }
        else
        {
            floatingTabBarBackgroundConstraints = [
                floatingTabBarBackgroundView.leadingAnchor.constraint(equalTo: self.tabBar.leadingAnchor),
                floatingTabBarBackgroundView.trailingAnchor.constraint(equalTo: self.tabBar.trailingAnchor),
                floatingTabBarBackgroundView.topAnchor.constraint(equalTo: self.tabBar.topAnchor),
                floatingTabBarBackgroundView.bottomAnchor.constraint(equalTo: self.tabBar.bottomAnchor),
            ]
            floatingTabBarBackgroundView.layer.cornerRadius = 0
            floatingTabBarBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            floatingTabBarBackgroundView.layer.masksToBounds = false
            floatingTabBarBackgroundView.layer.shadowOpacity = 0
        }

        NSLayoutConstraint.activate(floatingTabBarBackgroundConstraints)

        applyFloatingTabBarVisualStyle()
    }

    private func applyFloatingTabBarVisualStyle()
    {
        if #available(iOS 26.0, *) {
            floatingTabBarBackgroundView.contentView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.75)
            floatingTabBarBackgroundView.layer.shadowOpacity = 0.10
        }
        else
        {
            // Solid-enough backdrop so separators don’t flash through non–iOS-26 layouts.
            floatingTabBarBackgroundView.contentView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.94)
            floatingTabBarBackgroundView.layer.shadowOpacity = 0
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass
            || traitCollection.userInterfaceIdiom != previousTraitCollection?.userInterfaceIdiom
            else { return }
        self.updateFloatingTabBarConstraintsIfNeeded()
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
        self.selectedIndex = Tab.settings.rawValue
    }
}
