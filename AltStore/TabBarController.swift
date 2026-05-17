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
        self.view.backgroundColor = .systemBackground
        self.configureTabBarAppearance()
        self.configurePrimaryTabs()
    }

    /// Storyboard tab order: News (0), Browse (1), My Apps (2), Settings placeholder (3). We expose Browse, My Apps, Settings only.
    private func configurePrimaryTabs()
    {
        guard let vcs = self.viewControllers, vcs.count >= 4 else {
            assertionFailure("TabBarController expected 4 storyboard tabs (News, Browse, My Apps, Settings).")
            return
        }

        let browseNavigationController = vcs[1] as! UINavigationController
        browseNavigationController.tabBarItem.title = NSLocalizedString("Browse", comment: "")
        browseNavigationController.tabBarItem.image = UIImage(systemName: "square.grid.3x3.fill")
        browseNavigationController.navigationBar.prefersLargeTitles = true

        let myAppsNavigationController = vcs[2] as! UINavigationController
        myAppsNavigationController.tabBarItem.title = NSLocalizedString("My Apps", comment: "")
        myAppsNavigationController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        myAppsNavigationController.navigationBar.prefersLargeTitles = true

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
        let addHost = UIButton(type: .system)
        addHost.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addHost.addAction(addCatalogAction, for: .touchUpInside)
        addHost.accessibilityLabel = NSLocalizedString("Add catalog", comment: "")
        featured.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addHost)
        browseNavigationController.setViewControllers([featured], animated: false)

        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        let settingsNavigationController = settingsStoryboard.instantiateInitialViewController() as! UINavigationController
        settingsNavigationController.navigationBar.prefersLargeTitles = true
        settingsNavigationController.tabBarItem.title = NSLocalizedString("Settings", comment: "")
        settingsNavigationController.tabBarItem.image = UIImage(systemName: "gearshape.fill")

        self.viewControllers = [
            browseNavigationController,
            myAppsNavigationController,
            settingsNavigationController,
        ]
        self.selectedIndex = Tab.browse.rawValue
    }

    private func configureTabBarAppearance()
    {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .separator
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
        self.tabBar.isTranslucent = false

        if #available(iOS 26.0, *)
        {
            floatingTabBarBackgroundView.isHidden = true
            return
        }

        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
        self.tabBar.isTranslucent = true

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
        guard !floatingTabBarBackgroundView.isHidden else { return }
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

        floatingTabBarBackgroundConstraints = [
            floatingTabBarBackgroundView.leadingAnchor.constraint(equalTo: self.tabBar.leadingAnchor),
            floatingTabBarBackgroundView.trailingAnchor.constraint(equalTo: self.tabBar.trailingAnchor),
            floatingTabBarBackgroundView.topAnchor.constraint(equalTo: self.tabBar.topAnchor),
            floatingTabBarBackgroundView.bottomAnchor.constraint(equalTo: self.tabBar.bottomAnchor),
        ]
        floatingTabBarBackgroundView.layer.cornerRadius = 0
        floatingTabBarBackgroundView.layer.shadowOpacity = 0

        NSLayoutConstraint.activate(floatingTabBarBackgroundConstraints)
        applyFloatingTabBarVisualStyle()
    }

    private func applyFloatingTabBarVisualStyle()
    {
        floatingTabBarBackgroundView.contentView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.94)
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
