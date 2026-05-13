//
//  FluxIgnoredUpdatesViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024. All rights reserved.
//

import UIKit
import Nuke
import AltStoreCore

class FluxIgnoredUpdatesViewController: UITableViewController {
    
    private var ignoredUpdates: [String: String] = [:]
    private var apps: [InstalledApp] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Ignored Updates", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupNavigationBar()
        loadIgnoredUpdates()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(clearAllIgnored)
        )
    }
    
    private func loadIgnoredUpdates() {
        ignoredUpdates = FluxVersionManager.shared.getIgnoredUpdates()
        
        // Load app information
        apps = InstalledApp.all(in: DatabaseManager.shared.viewContext).filter { app in
            ignoredUpdates.keys.contains(app.bundleIdentifier)
        }
        
        tableView.reloadData()
    }
    
    @objc private func clearAllIgnored() {
        let alert = UIAlertController(
            title: NSLocalizedString("Clear All Ignored Updates?", comment: ""),
            message: NSLocalizedString("This will remove all ignored updates and you'll be notified about all available updates again.", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Clear All", comment: ""), style: .destructive) { _ in
            FluxVersionManager.shared.clearIgnoredUpdates()
            self.loadIgnoredUpdates()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FluxIgnoredUpdatesViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return apps.isEmpty ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && apps.isEmpty {
            return 1
        } else if section == 0 {
            return apps.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "IgnoredUpdateCell")
        cell.backgroundColor = .fluxCardBackground
        
        if apps.isEmpty && indexPath.section == 0 {
            cell.textLabel?.text = NSLocalizedString("No Ignored Updates", comment: "")
            cell.detailTextLabel?.text = NSLocalizedString("Updates you ignore will appear here", comment: "")
            cell.selectionStyle = .none
        } else if indexPath.section == 0 {
            let app = apps[indexPath.row]
            let ignoredVersion = ignoredUpdates[app.bundleIdentifier] ?? ""
            
            cell.textLabel?.text = app.name
            cell.detailTextLabel?.text = NSLocalizedString("Ignored version: \(ignoredVersion)", comment: "")
            cell.imageView?.image = UIImage(systemName: "app.fill")
            if let iconURL = app.storeApp?.iconURL {
                Nuke.loadImage(with: iconURL, into: cell.imageView!)
            }
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = NSLocalizedString("Clear All Ignored Updates", comment: "")
            cell.textLabel?.textColor = .systemRed
            cell.imageView?.image = UIImage(systemName: "trash.fill")
            cell.imageView?.tintColor = .systemRed
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("Ignored Updates", comment: "")
        } else if !apps.isEmpty {
            return NSLocalizedString("Actions", comment: "")
        }
        return nil
    }
}

// MARK: - UITableViewDelegate
extension FluxIgnoredUpdatesViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if apps.isEmpty && indexPath.section == 0 {
            return
        }
        
        if indexPath.section == 0 {
            let app = apps[indexPath.row]
            showUnignoreAlert(for: app)
        } else {
            clearAllIgnored()
        }
    }
    
    private func showUnignoreAlert(for app: InstalledApp) {
        let alert = UIAlertController(
            title: NSLocalizedString("Unignore Update?", comment: ""),
            message: NSLocalizedString("Do you want to receive update notifications for \(app.name) again?", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Unignore", comment: ""), style: .default) { _ in
            FluxVersionManager.shared.unignoreUpdate(for: app.bundleIdentifier)
            self.loadIgnoredUpdates()
        })
        
        present(alert, animated: true)
    }
}
