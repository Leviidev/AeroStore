//
//  FluxBrowseViewController.swift
//

import UIKit
import CoreData
import AltStoreCore

/// Flux Browse hub: App Store–style catalog rows, Flux-branded add flow, rich headers.
final class FluxBrowseViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    private enum Section: Int, CaseIterable {
        case yours = 0
        case picks = 1
    }

    private struct CatalogEntry {
        let identifier: String
        let url: URL
        let displayName: String?
        let tagline: String?
    }

    private struct TrustedAppsPayload: Decodable {
        let catalog: [TrustedRow]?
        let trusted: [TrustedRow]?
        let sources: [TrustedRow]?
    }

    private struct TrustedRow: Decodable {
        let identifier: String
        let sourceURL: String?
        let displayName: String?
        let tagline: String?
    }

    private lazy var fetchedSourcesController: NSFetchedResultsController<Source> = self.makeFetchedSourcesController()
    private let bundledCatalog: [CatalogEntry] = FluxBrowseViewController.loadBundledCatalogEntries()
    private var catalogRowsToShow: [CatalogEntry] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Browse", comment: "")
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView.backgroundColor = .altBackground
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 12
        tableView.register(FluxBrowseCatalogCell.self, forCellReuseIdentifier: FluxBrowseCatalogCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addCatalogTapped)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = NSLocalizedString("Add catalog", comment: "")

        fetchedSourcesController.delegate = self
        try? fetchedSourcesController.performFetch()
        refreshCatalogRows()
        rebuildHeader()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }

    private func rebuildHeader() {
        let host = UIView()
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: host.topAnchor),
            content.bottomAnchor.constraint(equalTo: host.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            content.widthAnchor.constraint(equalTo: host.widthAnchor),
        ])

        let logo = FluxLogoView()
        logo.translatesAutoresizingMaskIntoConstraints = false

        let headline = UILabel()
        headline.translatesAutoresizingMaskIntoConstraints = false
        headline.text = NSLocalizedString("Discover apps", comment: "")
        headline.font = .systemFont(ofSize: 28, weight: .bold)
        headline.textColor = .label

        let sub = UILabel()
        sub.translatesAutoresizingMaskIntoConstraints = false
        sub.text = NSLocalizedString("Flux picks showcase catalogs we trust. Your catalogs open rich browsing—screenshots, descriptions, and installs—without the legacy SideStore chrome.", comment: "")
        sub.font = .preferredFont(forTextStyle: .subheadline)
        sub.textColor = UIColor.fluxSecondaryText
        sub.numberOfLines = 0

        content.addSubview(logo)
        content.addSubview(headline)
        content.addSubview(sub)

        NSLayoutConstraint.activate([
            logo.topAnchor.constraint(equalTo: content.topAnchor, constant: 4),
            logo.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            logo.widthAnchor.constraint(equalToConstant: 64),
            logo.heightAnchor.constraint(equalToConstant: 64),

            headline.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 12),
            headline.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            headline.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            sub.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 8),
            sub.leadingAnchor.constraint(equalTo: headline.leadingAnchor),
            sub.trailingAnchor.constraint(equalTo: headline.trailingAnchor),
            sub.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),
        ])

        tableView.tableHeaderView = host
    }

    private func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }
        let target = tableView.bounds.width
        guard target > 0 else { return }

        header.frame.size.width = target
        header.setNeedsLayout()
        header.layoutIfNeeded()

        let height = header.systemLayoutSizeFitting(
            CGSize(width: target, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        if abs(header.frame.height - height) > 0.5 {
            header.frame.size.height = height
            tableView.tableHeaderView = header
        }
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
              let decoded = try? Foundation.JSONDecoder().decode(TrustedAppsPayload.self, from: data)
        else {
            return []
        }

        let merged = (decoded.catalog ?? []) + (decoded.sources ?? []) + (decoded.trusted ?? [])
        var seen = Set<String>()
        var result: [CatalogEntry] = []

        for row in merged {
            guard seen.insert(row.identifier).inserted else { continue }
            guard let urlString = row.sourceURL, let u = URL(string: urlString) else { continue }
            if isExcludedSidestoreOfficial(url: u, identifier: row.identifier) { continue }
            result.append(CatalogEntry(identifier: row.identifier, url: u, displayName: row.displayName, tagline: row.tagline))
        }

        return result
    }

    private static func isExcludedSidestoreOfficial(url: URL, identifier: String) -> Bool {
        if identifier == Source.altStoreIdentifier { return true }
        let normalized = (try? Source.sourceID(from: url)) ?? ""
        return normalized == Source.altStoreIdentifier
    }

    @objc private func addCatalogTapped() {
        presentFluxAddCatalog(prefilled: nil)
    }

    private func presentFluxAddCatalog(prefilled: URL?) {
        let add = FluxAddCatalogViewController()
        add.prefilledURL = prefilled
        let nav = UINavigationController(rootViewController: add)
        nav.modalPresentationStyle = .formSheet
        nav.navigationBar.prefersLargeTitles = false
        present(nav, animated: true)
    }

    // MARK: UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .yours: return fetchedSourcesController.fetchedObjects?.count ?? 0
        case .picks: return catalogRowsToShow.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .yours: return NSLocalizedString("Your catalogs", comment: "")
        case .picks: return NSLocalizedString("Flux picks", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FluxBrowseCatalogCell.reuseID, for: indexPath) as! FluxBrowseCatalogCell

        switch Section(rawValue: indexPath.section)! {
        case .yours:
            guard let source = fetchedSourcesController.fetchedObjects?[indexPath.row] else { return cell }
            let host = source.sourceURL.host ?? source.identifier
            let subtitle: String
            if let s = source.subtitle, !s.isEmpty {
                subtitle = s
            } else {
                subtitle = NSLocalizedString("Browse releases, screenshots, and details in the Flux catalog.", comment: "")
            }

            cell.configure(title: source.name, subtitle: subtitle, meta: host, mode: .ownedChevron)
            cell.applyVisuals(mode: .ownedChevron, artworkURL: source.effectiveIconURL, pickGlyph: "sparkles.rectangle.stack")

        case .picks:
            let entry = catalogRowsToShow[indexPath.row]
            let title = entry.displayName ?? prettifyIdentifier(entry.identifier)
            let tagline = entry.tagline ?? NSLocalizedString("Curated catalog • Tap to preview and add", comment: "")
            let host = entry.url.host ?? ""
            cell.configure(title: title, subtitle: tagline, meta: host, mode: .addCatalog)
            cell.applyVisuals(mode: .addCatalog, artworkURL: nil, pickGlyph: "star.fill")
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {
        case .yours:
            guard let source = fetchedSourcesController.fetchedObjects?[indexPath.row] else { return }
            let detail = FluxCatalogDetailViewController(source: source)
            navigationController?.pushViewController(detail, animated: true)

        case .picks:
            let entry = catalogRowsToShow[indexPath.row]
            presentFluxAddCatalog(prefilled: entry.url)
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch Section(rawValue: section)! {
        case .picks where catalogRowsToShow.isEmpty: return UITableView.automaticDimension
        default: return 10
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section)! == .picks, catalogRowsToShow.isEmpty else { return nil }
        return NSLocalizedString("You’ve added every Flux pick. Use + to paste any catalog URL.", comment: "")
    }

    private func prettifyIdentifier(_ id: String) -> String {
        let tail = id.split(separator: ".").last.map(String.init) ?? id
        return tail.replacingOccurrences(of: "_", with: " ").capitalized
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshCatalogRows()
        tableView.reloadData()
    }
}
