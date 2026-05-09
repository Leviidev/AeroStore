//
//  FluxHomeViewController.swift
//  AltStore
//

import UIKit
import AltStoreCore

/// Home tab: FluxStore update, quick navigation, and summary of app updates.
final class FluxHomeViewController: UITableViewController
{
    private enum Section: Int, CaseIterable
    {
        case fluxStoreUpdate
        case goFurther
        case yourApps
    }

    private var fluxUpdate: FluxStoreGitHubRelease.UpdateInfo?
    private var pendingAppUpdatesCount = 0
    private var isFetchingRelease = false

    init()
    {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        title = NSLocalizedString("Home", comment: "")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .altBackground
        navigationItem.largeTitleDisplayMode = .always
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        refreshSummary()
        refreshFluxRelease()
    }

    private func refreshSummary()
    {
        let request = InstalledApp.supportedUpdatesFetchRequest()
        pendingAppUpdatesCount = (try? DatabaseManager.shared.viewContext.count(for: request)) ?? 0
        tableView.reloadSections(IndexSet(integer: Section.yourApps.rawValue), with: .automatic)
    }

    private func refreshFluxRelease()
    {
        guard !isFetchingRelease else { return }
        isFetchingRelease = true
        Task { @MainActor in
            defer { self.isFetchingRelease = false }
            self.fluxUpdate = await FluxStoreGitHubRelease.fetchNewerReleaseIfAvailable()
            self.tableView.reloadSections(IndexSet(integer: Section.fluxStoreUpdate.rawValue), with: .automatic)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch Section(rawValue: section)!
        {
        case .fluxStoreUpdate: return fluxUpdate == nil ? 0 : 1
        case .goFurther: return 2
        case .yourApps: return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        switch Section(rawValue: section)!
        {
        case .fluxStoreUpdate: return fluxUpdate == nil ? nil : NSLocalizedString("FLUXSTORE", comment: "")
        case .goFurther: return NSLocalizedString("DISCOVER", comment: "")
        case .yourApps: return NSLocalizedString("YOUR APPS", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .fluxCardBackground
        cell.tintColor = .altPrimary
        var content = UIListContentConfiguration.cell()
        content.textProperties.color = .label
        content.secondaryTextProperties.color = .fluxSecondaryText
        content.imageProperties.tintColor = .altPrimary
        content.prefersSideBySideTextAndSecondaryText = false

        switch Section(rawValue: indexPath.section)!
        {
        case .fluxStoreUpdate:
            if let info = fluxUpdate
            {
                content.text = String(format: NSLocalizedString("Update to %@ available", comment: ""), info.versionString)
                content.secondaryText = NSLocalizedString("Download the latest IPA from GitHub", comment: "")
                content.image = UIImage(systemName: "arrow.down.circle.fill")
                cell.accessoryType = .disclosureIndicator
            }

        case .goFurther:
            cell.accessoryType = .disclosureIndicator
            switch indexPath.row
            {
            case 0:
                content.text = NSLocalizedString("Browse", comment: "")
                content.secondaryText = NSLocalizedString("Featured apps and catalogs", comment: "")
                content.image = UIImage(systemName: "sparkles")
            case 1:
                content.text = NSLocalizedString("My Apps", comment: "")
                content.secondaryText = NSLocalizedString("Installed apps, refreshes, and updates", comment: "")
                content.image = UIImage(systemName: "square.grid.2x2")
            default: break
            }

        case .yourApps:
            if pendingAppUpdatesCount == 0
            {
                content.text = NSLocalizedString("No app updates pending", comment: "")
                content.secondaryText = NSLocalizedString("Pull to refresh on My Apps to check sources", comment: "")
                content.image = UIImage(systemName: "checkmark.circle")
                cell.accessoryType = .none
            }
            else
            {
                content.text = String(format: NSLocalizedString("%lld updates available", comment: ""), Int64(pendingAppUpdatesCount))
                content.secondaryText = NSLocalizedString("Open My Apps to refresh or install", comment: "")
                content.image = UIImage(systemName: "arrow.triangle.2.circlepath")
                cell.accessoryType = .disclosureIndicator
            }
        }

        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let tab = tabBarController as? TabBarController else { return }

        switch Section(rawValue: indexPath.section)!
        {
        case .fluxStoreUpdate:
            if let info = fluxUpdate { FluxStoreGitHubRelease.openUpdate(info) }

        case .goFurther:
            switch indexPath.row
            {
            case 0: tab.selectedIndex = TabBarController.Tab.browse.rawValue
            case 1: tab.selectedIndex = TabBarController.Tab.myApps.rawValue
            default: break
            }

        case .yourApps:
            tab.selectedIndex = TabBarController.Tab.myApps.rawValue
        }
    }
}
