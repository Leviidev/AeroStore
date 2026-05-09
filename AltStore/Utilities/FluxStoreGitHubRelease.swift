//
//  FluxStoreGitHubRelease.swift
//  AltStore
//

import Foundation
import UIKit
import SemanticVersion

/// Checks GitHub Releases for a build newer than the running app (`CFBundleShortVersionString`).
enum FluxStoreGitHubRelease
{
    private static let latestReleaseAPIURL = URL(string: "https://api.github.com/repos/FluxStore-App/FluxStore/releases/latest")!

    struct UpdateInfo: Equatable
    {
        let tagName: String
        let versionString: String
        let releaseWebURL: URL
        let ipaDownloadURL: URL?
    }

    private struct APIRelease: Decodable
    {
        struct Asset: Decodable
        {
            let name: String
            let browser_download_url: URL
        }

        let tag_name: String
        let html_url: URL
        let assets: [Asset]
    }

    /// Fetches the latest release; returns `nil` if the network fails, JSON is invalid, or the remote version is not greater than the installed app.
    static func fetchNewerReleaseIfAvailable() async -> UpdateInfo?
    {
        var request = URLRequest(url: latestReleaseAPIURL)
        request.setValue("FluxStore-iOS/\(marketingVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do
        {
            (data, response) = try await URLSession.shared.data(for: request)
        }
        catch
        {
            return nil
        }

        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else
        {
            return nil
        }

        let release: APIRelease
        do
        {
            release = try JSONDecoder().decode(APIRelease.self, from: data)
        }
        catch
        {
            return nil
        }

        let remoteVersion = normalizedVersion(fromTag: release.tag_name)
        let localVersion = marketingVersion
        guard isVersion(remoteVersion, newerThan: localVersion) else { return nil }

        let ipaURL = release.assets.first(where: { $0.name.lowercased().hasSuffix(".ipa") })?.browser_download_url

        return UpdateInfo(
            tagName: release.tag_name,
            versionString: remoteVersion,
            releaseWebURL: release.html_url,
            ipaDownloadURL: ipaURL
        )
    }

    /// Opens the IPA download when available; otherwise the release page (or static latest URL).
    static func openUpdate(_ info: UpdateInfo)
    {
        let url = info.ipaDownloadURL ?? info.releaseWebURL
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private static var marketingVersion: String
    {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
    }

    private static func normalizedVersion(fromTag tag: String) -> String
    {
        let t = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("v") || t.hasPrefix("V")
        {
            return String(t.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t
    }

    private static func isVersion(_ a: String, newerThan b: String) -> Bool
    {
        if let va = SemanticVersion(a), let vb = SemanticVersion(b)
        {
            return va > vb
        }
        return a.compare(b, options: .numeric) == .orderedDescending
    }
}
