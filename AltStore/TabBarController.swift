//
//  TabBarController.swift
//  AltStore
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

    static func makeMainInterface() -> TabBarController {
        let tabBar = TabBarController()
        tabBar.configurePrimaryTabs()
        return tabBar
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        registerForNotifications()
    }

    init()
    {
        super.init(nibName: nil, bundle: nil)
        registerForNotifications()
    }

    private func registerForNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.importApp(_:)), name: AppDelegate.importAppDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.presentSources(_:)), name: AppDelegate.addSourceDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.exportFiles(_:)), name: AppDelegate.exportCertificateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.openErrorLog(_:)), name: ToastView.openErrorLogNotification, object: nil)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureTabBarAppearance()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        if viewControllers?.isEmpty != false {
            configurePrimaryTabs()
        }
    }

    func configurePrimaryTabs()
    {
        let main = UIStoryboard(name: "Main", bundle: nil)
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)

        let browseNavigationController = Self.instantiateBrowseNavigationController(main: main)
        let myAppsNavigationController = Self.instantiateMyAppsNavigationController(main: main)
        guard let settingsNavigationController = settingsStoryboard.instantiateInitialViewController() as? UINavigationController else {
            print("❌ TabBarController: Settings storyboard failed to load")
            return
        }

        settingsNavigationController.navigationBar.prefersLargeTitles = true
        settingsNavigationController.tabBarItem.title = NSLocalizedString("Settings", comment: "")
        settingsNavigationController.tabBarItem.image = UIImage(systemName: "gearshape.fill")

        viewControllers = [
            browseNavigationController,
            myAppsNavigationController,
            settingsNavigationController,
        ]
        selectedIndex = Tab.browse.rawValue
    }

    private static func instantiateBrowseNavigationController(main: UIStoryboard) -> UINavigationController
    {
        if let nav = main.instantiateViewController(withIdentifier: "browseNavigationController") as? UINavigationController {
            nav.tabBarItem.title = NSLocalizedString("Browse", comment: "")
            nav.tabBarItem.image = UIImage(systemName: "square.grid.3x3.fill")
            nav.navigationBar.prefersLargeTitles = true
            if let featured = nav.viewControllers.first as? FeaturedViewController {
                configureFeaturedBrowseActions(featured)
            } else {
                let featured = main.instantiateViewController(withIdentifier: "featuredViewController") as! FeaturedViewController
                featured.navigationItem.largeTitleDisplayMode = .always
                configureFeaturedBrowseActions(featured)
                nav.setViewControllers([featured], animated: false)
            }
            return nav
        }

        let featured = main.instantiateViewController(withIdentifier: "featuredViewController") as! FeaturedViewController
        featured.navigationItem.largeTitleDisplayMode = .always
        configureFeaturedBrowseActions(featured)
        let nav = UINavigationController(rootViewController: featured)
        nav.tabBarItem.title = NSLocalizedString("Browse", comment: "")
        nav.tabBarItem.image = UIImage(systemName: "square.grid.3x3.fill")
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }

    private static func instantiateMyAppsNavigationController(main: UIStoryboard) -> UINavigationController
    {
        if let nav = main.instantiateViewController(withIdentifier: "myAppsNavigationController") as? UINavigationController {
            nav.tabBarItem.title = NSLocalizedString("My Apps", comment: "")
            nav.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
            nav.navigationBar.prefersLargeTitles = true
            return nav
        }

        if let myApps = main.instantiateViewController(withIdentifier: "myAppsViewController") as? MyAppsViewController {
            let nav = UINavigationController(rootViewController: myApps)
            nav.tabBarItem.title = NSLocalizedString("My Apps", comment: "")
            nav.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
            nav.navigationBar.prefersLargeTitles = true
            return nav
        }

        print("❌ TabBarController: My Apps storyboard identifiers missing; using placeholder")
        let placeholder = UIViewController()
        placeholder.view.backgroundColor = .systemBackground
        placeholder.tabBarItem.title = NSLocalizedString("My Apps", comment: "")
        placeholder.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        return UINavigationController(rootViewController: placeholder)
    }

    private static func configureFeaturedBrowseActions(_ featured: FeaturedViewController)
    {
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

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .altPrimary
        tabBar.unselectedItemTintColor = .fluxSecondaryText
        tabBar.isTranslucent = false

        if #available(iOS 26.0, *)
        {
            floatingTabBarBackgroundView.isHidden = true
            return
        }

        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true

        floatingTabBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        floatingTabBarBackgroundView.isUserInteractionEnabled = false
        tabBar.insertSubview(floatingTabBarBackgroundView, at: 0)
        updateFloatingTabBarConstraintsIfNeeded()
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        updateFloatingTabBarConstraintsIfNeeded()
    }

    private func updateFloatingTabBarConstraintsIfNeeded()
    {
        guard floatingTabBarBackgroundView.superview === tabBar else { return }
        NSLayoutConstraint.deactivate(floatingTabBarBackgroundConstraints)
        floatingTabBarBackgroundConstraints = [
            floatingTabBarBackgroundView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            floatingTabBarBackgroundView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            floatingTabBarBackgroundView.topAnchor.constraint(equalTo: tabBar.topAnchor),
            floatingTabBarBackgroundView.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
        ]
        NSLayoutConstraint.activate(floatingTabBarBackgroundConstraints)
        floatingTabBarBackgroundView.contentView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.94)
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        _viewDidAppear = true
        if let (identifier, sender) = initialSegue {
            initialSegue = nil
            performSegue(withIdentifier: identifier, sender: sender)
        }
    }

    override func performSegue(withIdentifier identifier: String, sender: Any?)
    {
        guard _viewDidAppear else {
            initialSegue = (identifier, sender)
            return
        }
        super.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension TabBarController
{
    @objc func presentSources(_ sender: Any)
    {
        selectedIndex = Tab.browse.rawValue
    }
}

private extension TabBarController
{
    @objc func importApp(_ notification: Notification)
    {
        selectedIndex = Tab.myApps.rawValue
    }

    @objc func openErrorLog(_ notification: Notification)
    {
        presentSettings()
    }

    @objc func exportFiles(_ notification: Notification)
    {
        presentSettings()
    }

    func presentSettings()
    {
        selectedIndex = Tab.settings.rawValue
    }
}
