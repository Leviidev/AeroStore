//
//  AppRefreshScheduleManager.swift
//  AeroStore
//
//  Manages per-app background refresh intervals. Apps can have a custom
//  refresh interval (1, 2, 4, 8, 12, or 24 hours). Apps with no custom
//  interval use the system default of 6 hours.
//

import Foundation
import AltStoreCore

class AppRefreshScheduleManager {

    static let shared = AppRefreshScheduleManager()

    static let defaultIntervalHours: Int = 6
    static let minimumIntervalHours: Int = 1
    static let availableIntervals: [(label: String, hours: Int)] = [
        ("1 Hour",   1),
        ("2 Hours",  2),
        ("4 Hours",  4),
        ("6 Hours (Default)", 6),
        ("8 Hours",  8),
        ("12 Hours", 12),
        ("24 Hours", 24),
    ]

    private init() {}

    // MARK: - Read / Write

    func refreshIntervalHours(for bundleIdentifier: String) -> Int {
        return UserDefaults.standard.appRefreshIntervals[bundleIdentifier]
            ?? AppRefreshScheduleManager.defaultIntervalHours
    }

    func setRefreshIntervalHours(_ hours: Int, for bundleIdentifier: String) {
        var intervals = UserDefaults.standard.appRefreshIntervals
        intervals[bundleIdentifier] = hours
        UserDefaults.standard.appRefreshIntervals = intervals
    }

    func resetToDefault(for bundleIdentifier: String) {
        var intervals = UserDefaults.standard.appRefreshIntervals
        intervals.removeValue(forKey: bundleIdentifier)
        UserDefaults.standard.appRefreshIntervals = intervals
    }

    func hasCustomInterval(for bundleIdentifier: String) -> Bool {
        return UserDefaults.standard.appRefreshIntervals[bundleIdentifier] != nil
    }

    // MARK: - Schedule Checking

    func cutoffDate(for bundleIdentifier: String) -> Date {
        let hours = refreshIntervalHours(for: bundleIdentifier)
        return Date().addingTimeInterval(-Double(hours) * 3600)
    }

    func isDueForRefresh(_ app: InstalledApp) -> Bool {
        return app.refreshedDate < cutoffDate(for: app.bundleIdentifier)
    }
}
