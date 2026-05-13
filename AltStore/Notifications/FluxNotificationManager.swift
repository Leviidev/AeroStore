//
//  FluxNotificationManager.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024. All rights reserved.
//

import UIKit
import UserNotifications
import AltStoreCore

// MARK: - FluxNotification Model

struct FluxNotification {
    let id: String
    let title: String
    let message: String
    let category: FluxNotificationCategory
    let userInfo: [String: Any]
    let date: Date
    let isRead: Bool
    
    init(id: String = UUID().uuidString, title: String, message: String, category: FluxNotificationCategory, userInfo: [String: Any] = [:], date: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.category = category
        self.userInfo = userInfo
        self.date = date
        self.isRead = isRead
    }

    init(id: String = UUID().uuidString, title: String, body: String, category: FluxNotificationCategory, userInfo: [String: Any] = [:], date: Date = Date(), isRead: Bool = false) {
        self.init(id: id, title: title, message: body, category: category, userInfo: userInfo, date: date, isRead: isRead)
    }

    var body: String {
        message
    }
}

enum FluxNotificationCategory {
    case appUpdate
    case refreshReminder
    case certificateWarning
    case jitStatus
    case system
    case general
    
    var localizedTitle: String {
        switch self {
        case .appUpdate:
            return NSLocalizedString("App Update", comment: "")
        case .refreshReminder:
            return NSLocalizedString("Refresh Reminder", comment: "")
        case .certificateWarning:
            return NSLocalizedString("Certificate Warning", comment: "")
        case .jitStatus:
            return NSLocalizedString("JIT Status", comment: "")
        case .system:
            return NSLocalizedString("System", comment: "")
        case .general:
            return NSLocalizedString("General", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .appUpdate:
            return "arrow.up.circle.fill"
        case .refreshReminder:
            return "clock.circle.fill"
        case .certificateWarning:
            return "exclamationmark.triangle.fill"
        case .jitStatus:
            return "bolt.circle.fill"
        case .system:
            return "gear.circle.fill"
        case .general:
            return "bell.circle.fill"
        }
    }
    
    var color: UIColor {
        switch self {
        case .appUpdate:
            return .systemBlue
        case .refreshReminder:
            return .systemOrange
        case .certificateWarning:
            return .systemYellow
        case .jitStatus:
            return .systemTeal
        case .system:
            return .systemGray
        case .general:
            return .systemPurple
        }
    }
}

class FluxNotificationManager: NSObject {
    
    static let shared = FluxNotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let refreshReminderKey = "FluxStore.refreshReminder"
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Permission Management
    
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Refresh Reminders
    
    func scheduleRefreshReminder(for app: App) {
        guard let expirationDate = app.expirationDate else { return }
        
        let reminderDays = [2, 1] // Remind 2 days and 1 day before expiry
        
        for days in reminderDays {
            let reminderDate = Calendar.current.date(byAdding: .day, value: -days, to: expirationDate)!
            
            // Only schedule if reminder date is in the future
            if reminderDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("FluxStore Refresh Needed", comment: "")
                content.body = String(format: NSLocalizedString("%@ will expire in %d day(s). Please refresh it to prevent expiration.", comment: ""), app.name, days)
                content.sound = .default
                content.badge = 1
                content.userInfo = [
                    "type": "refresh_reminder",
                    "appBundleIdentifier": app.bundleIdentifier,
                    "days": days
                ]
                
                let identifier = "\(refreshReminderKey)_\(app.bundleIdentifier)_\(days)"
                let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate), repeats: false)
                
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                notificationCenter.add(request) { error in
                    if let error = error {
                        print("Failed to schedule refresh reminder: \(error)")
                    }
                }
            }
        }
    }
    
    func cancelRefreshReminder(for app: App) {
        let identifiers = ["\(refreshReminderKey)_\(app.bundleIdentifier)_1", "\(refreshReminderKey)_\(app.bundleIdentifier)_2"]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func scheduleAllRefreshReminders() {
        let apps = DatabaseManager.shared.apps(of: .any)
        
        for app in apps {
            if app.isRefreshing || app.needsRefresh {
                scheduleRefreshReminder(for: app)
            }
        }
    }
    
    func cancelAllRefreshReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Update Notifications
    
    func scheduleUpdateNotification(for app: App, newVersion: String, updateType: UpdateType) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("FluxStore Update Available", comment: "")
        
        switch updateType {
        case .standard:
            content.body = String(format: NSLocalizedString("%@ version %@ is now available.", comment: ""), app.name, newVersion)
        case .nightly:
            content.body = String(format: NSLocalizedString("%@ nightly build %@ is now available.", comment: ""), app.name, newVersion)
        case .stableFromNightly:
            content.body = String(format: NSLocalizedString("%@ stable version %@ is now available (from nightly).", comment: ""), app.name, newVersion)
        }
        
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "update_available",
            "appBundleIdentifier": app.bundleIdentifier,
            "newVersion": newVersion,
            "updateType": updateType.rawValue
        ]
        
        // Schedule immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "update_\(app.bundleIdentifier)_\(newVersion)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule update notification: \(error)")
            }
        }
    }
    
    // MARK: - Settings Integration
    
    func updateNotificationSettings() {
        let settings = UserDefaults.standard
        
        if settings.bool(forKey: "FluxStore.refreshNotificationsEnabled") {
            scheduleAllRefreshReminders()
        } else {
            cancelAllRefreshReminders()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension FluxNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleNotificationResponse(response)
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "refresh_reminder":
            handleRefreshReminder(userInfo: userInfo)
        case "update_available":
            handleUpdateAvailable(userInfo: userInfo)
        default:
            break
        }
    }
    
    private func handleRefreshReminder(userInfo: [AnyHashable: Any]) {
        guard let appBundleIdentifier = userInfo["appBundleIdentifier"] as? String else { return }
        
        // Navigate to the app and trigger refresh
        NotificationCenter.default.post(name: .fluxRefreshApp, object: nil, userInfo: [
            "appBundleIdentifier": appBundleIdentifier
        ])
    }
    
    private func handleUpdateAvailable(userInfo: [AnyHashable: Any]) {
        guard let appBundleIdentifier = userInfo["appBundleIdentifier"] as? String else { return }
        
        // Navigate to the app in My Apps
        NotificationCenter.default.post(name: .fluxShowApp, object: nil, userInfo: [
            "appBundleIdentifier": appBundleIdentifier
        ])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let fluxRefreshApp = Notification.Name("FluxRefreshApp")
    static let fluxShowApp = Notification.Name("FluxShowApp")
}

// MARK: - UpdateType Extension

extension UpdateType {
    var rawValue: String {
        switch self {
        case .standard:
            return "standard"
        case .nightly:
            return "nightly"
        case .stableFromNightly:
            return "stableFromNightly"
        }
    }
}
