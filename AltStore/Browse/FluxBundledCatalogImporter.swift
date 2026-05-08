//
//  FluxBundledCatalogImporter.swift
//

import CoreData
import Foundation
import AltStoreCore

/// Imports `trustedapps.json` catalogs into Core Data so Browse (Featured) shows apps like the App Store
/// without an “add source” sheet. User-added URLs still use the + flow.
enum FluxBundledCatalogImporter {

    private struct CatalogEntry {
        let identifier: String
        let url: URL
    }

    private struct TrustedAppsPayload: Decodable {
        let catalog: [TrustedRow]?
        let trusted: [TrustedRow]?
        let sources: [TrustedRow]?
    }

    private struct TrustedRow: Decodable {
        let identifier: String
        let sourceURL: String?
    }

    /// Call after `DatabaseManager` has started successfully.
    static func startImportWhenReady() {
        Task { @MainActor in
            await importMissingBundledCatalogs()
        }
    }

    @MainActor
    private static func importMissingBundledCatalogs() async {
        let ctx = DatabaseManager.shared.viewContext

        for entry in loadBundledCatalogEntries() {
            let normalizedID = (try? Source.sourceID(from: entry.url)) ?? ""
            guard !normalizedID.isEmpty, normalizedID != Source.altStoreIdentifier else { continue }

            let existing = Source.fetchRequest() as NSFetchRequest<Source>
            existing.predicate = NSPredicate(format: "%K == %@", #keyPath(Source.identifier), normalizedID)
            existing.fetchLimit = 1
            let count = (try? ctx.count(for: existing)) ?? 0
            guard count == 0 else { continue }

            do {
                _ = try await AppManager.shared.fetchSource(sourceURL: entry.url, managedObjectContext: ctx)
                try ctx.save()
            } catch {
                Logger.main.error("Flux bundled catalog import failed for \(entry.url.absoluteString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
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
            result.append(CatalogEntry(identifier: row.identifier, url: u))
        }

        return result
    }

    private static func isExcludedSidestoreOfficial(url: URL, identifier: String) -> Bool {
        if identifier == Source.altStoreIdentifier { return true }
        let normalized = (try? Source.sourceID(from: url)) ?? ""
        return normalized == Source.altStoreIdentifier
    }
}
