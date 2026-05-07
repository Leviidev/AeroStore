//
//  FluxBrowseSourcesViewController.swift
//  FluxStore / AltStore
//

import UIKit
import CoreData
import AltStoreCore

/// Browse tab: Flux-specific sources hub (distinct from legacy SideStore browse UI).
final class FluxBrowseSourcesViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    private enum Section: Int, CaseIterable {
        case yours = 0
        case catalog = 1
    }

    private struct CatalogEntry {
        let identifier: String
        let url: URL
    }

    private struct TrustedAppsPayload: Decodable {
        let trusted: [TrustedRow]?
        let sources: [TrustedRow]?
    }

    private struct TrustedRow: Decodable {
        let identifier: String
        let sourceURL: String?
    }

    private lazy var fetchedSourcesController: NSFetchedResultsController<Source> = self.makeFetchedSourcesController()

    /// Bundled curated catalogs (excluding SideStore official source).
    private let bundledCatalog: [CatalogEntry] = FluxBrowseSourcesViewController.loadBundledCatalogEntries()

    /// Catalog rows not yet added (by normalized source id).
    private var catalogRowsToShow: [CatalogEntry] = []

    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Browse", comment: "")
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        tableView.backgroundColor = .altBackground
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 8

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addSourceTapped)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = NSLocalizedString("Add Source", comment: "")

        fetchedSourcesController.delegate = self
        try? fetchedSourcesController.performFetch()

        refreshCatalogRows()
    }

    private func makeFetchedSourcesController() -> NSFetchedResultsController<Source> {
        let request = Source.fetchRequest() as NSFetchRequest<Source>
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Source.name, ascending: true),
            NSSortDescriptor(keyPath: \Source.identifier, ascending: true),
        ]
        request.predicate = NSPredicate(format: "%K != %@", #keyPath(Source.identifier), Source.altStoreIdentifier)
        request.returnsObjectsAsFaults = false

        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: DatabaseManager.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    private func installedSourceIdentifiers() -> Set<String> {
        Set((fetchedSourcesController.fetchedObjects ?? []).map(\.identifier))
    }

    private func refreshCatalogRows() {
        let installed = installedSourceIdentifiers()
        catalogRowsToShow = bundledCatalog.filter { entry in
            let normalizedID = (try? Source.sourceID(from: entry.url)) ?? ""
            return !installed.contains(normalizedID) && normalizedID != Source.altStoreIdentifier
        }
    }

    private static func loadBundledCatalogEntries() -> [CatalogEntry] {
        guard let url = Bundle.main.url(forResource: "trustedapps", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(TrustedAppsPayload.self, from: data)
        else {
            return []
        }

        let merged = (decoded.sources ?? []) + (decoded.trusted ?? [])
        var seen = Set<String>()
        var result: [CatalogEntry] = []

        for row in merged {
            guard seen.insert(row.identifier).inserted else { continue }
            guard let urlString = row.sourceURL, let u = URL(string: urlString) else { continue }

            if Self.isExcludedSidestoreOfficial(url: u, identifier: row.identifier) {
                continue
            }

            result.append(CatalogEntry(identifier: row.identifier, url: u))
        }

        return result
    }

    /// Hide SideStore’s primary catalog (`apps-v2.json`); community sources may still use sidestore hosts.
    private static func isExcludedSidestoreOfficial(url: URL, identifier: String) -> Bool {
        if identifier == Source.altStoreIdentifier { return true }
        let normalized = (try? Source.sourceID(from: url)) ?? ""
        if normalized == Source.altStoreIdentifier { return true }
        return false
    }

    @objc private func addSourceTapped() {
        presentAddSource(prefilled: nil)
    }

    private func presentAddSource(prefilled: URL?) {
        let storyboard = UIStoryboard(name: "Sources", bundle: nil)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: "addSourceNavigationController") as? UINavigationController else {
            return
        }
        if let addVC = navigationController.viewControllers.first as? AddSourceViewController {
            addVC.prefilledSourceURL = prefilled
        }
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }

    private func pushBrowseApps(for source: Source) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let browse = storyboard.instantiateViewController(identifier: "browseViewController") { coder in
            BrowseViewController(source: source, coder: coder)
        }
        navigationController?.pushViewController(browse, animated: true)
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .yours: return fetchedSourcesController.fetchedObjects?.count ?? 0
        case .catalog: return catalogRowsToShow.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .yours: return NSLocalizedString("Your sources", comment: "")
        case .catalog: return NSLocalizedString("Flux picks", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fluxSourceCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "fluxSourceCell")

        cell.backgroundColor = .clear
        cell.selectionStyle = .default

        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = UIColor.fluxCardBackground
        bg.cornerRadius = 16
        cell.backgroundConfiguration = bg

        switch Section(rawValue: indexPath.section)! {
        case .yours:
            guard let source = fetchedSourcesController.fetchedObjects?[indexPath.row] else { return cell }
            cell.textLabel?.text = source.name
            cell.textLabel?.textColor = .label
            cell.textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)

            let subtitle: String
            if let s = source.subtitle, !s.isEmpty {
                subtitle = s
            } else if let scheme = source.sourceURL.scheme {
                subtitle = source.sourceURL.absoluteString.replacingOccurrences(of: scheme + "://", with: "")
            } else {
                subtitle = source.sourceURL.absoluteString
            }
            cell.detailTextLabel?.text = subtitle
            cell.detailTextLabel?.textColor = UIColor.fluxSecondaryText
            cell.detailTextLabel?.numberOfLines = 2
            cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.right"))
            cell.accessoryView?.tintColor = UIColor.fluxSecondaryText
            cell.accessoryType = .none

        case .catalog:
            let entry = catalogRowsToShow[indexPath.row]
            let host = entry.url.host ?? entry.identifier
            cell.textLabel?.text = host
            cell.textLabel?.textColor = .label
            cell.textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            cell.detailTextLabel?.text = entry.identifier
            cell.detailTextLabel?.textColor = UIColor.fluxSecondaryText
            cell.detailTextLabel?.numberOfLines = 1

            let icon = UIImage(systemName: "plus.circle.fill")
            cell.accessoryView = UIImageView(image: icon)
            cell.accessoryView?.tintColor = .altPrimary
            cell.accessoryType = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {
        case .yours:
            guard let source = fetchedSourcesController.fetchedObjects?[indexPath.row] else { return }
            pushBrowseApps(for: source)

        case .catalog:
            let entry = catalogRowsToShow[indexPath.row]
            presentAddSource(prefilled: entry.url)
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch Section(rawValue: section)! {
        case .catalog where catalogRowsToShow.isEmpty: return UITableView.automaticDimension
        default: return 8
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section)! == .catalog, catalogRowsToShow.isEmpty else { return nil }
        return NSLocalizedString("Every catalog here is also listed under Sources once you add it.", comment: "")
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshCatalogRows()
        tableView.reloadData()
    }
}
