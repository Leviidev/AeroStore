//
//  FluxToolsViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024 FluxStore. All rights reserved.
//

import UIKit
import SwiftUI
import Intents
import IntentsUI

class FluxToolsViewController: UIViewController {
    
    private let tools = [
        ToolItem(title: "Custom Themes", icon: "paintbrush.fill", description: "Personalize your app appearance"),
        ToolItem(title: "Performance Monitor", icon: "speedometer", description: "Track app performance and resource usage"),
        ToolItem(title: "Shortcuts", icon: "bolt.fill", description: "Create Siri shortcuts for common actions"),
        ToolItem(title: "Device Info", icon: "info.circle.fill", description: "View detailed device information"),
        ToolItem(title: "Cache Manager", icon: "trash.fill", description: "Clear app cache and temporary files"),
        ToolItem(title: "Batch Operations", icon: "square.stack.3d.up.fill", description: "Install or update multiple apps at once"),
        ToolItem(title: "Backup & Restore", icon: "icloud.and.arrow.up.fill", description: "Backup your app configurations"),
        ToolItem(title: "Privacy Settings", icon: "lock.shield.fill", description: "Manage app permissions and privacy")
    ]
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .fluxCardBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(ToolCell.self, forCellWithReuseIdentifier: "ToolCell")
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Tools", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupCollectionView()
        setupNavigationBar()
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .altBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        appearance.shadowColor = UIColor.fluxCardBorder
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }
}

// MARK: - UICollectionViewDataSource
extension FluxToolsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tools.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ToolCell", for: indexPath) as! ToolCell
        cell.configure(with: tools[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FluxToolsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 40 // 20 left + 20 right
        let availableWidth = collectionView.frame.width - padding
        let itemWidth = (availableWidth - 16) / 2 // 2 columns with 16pt spacing
        return CGSize(width: itemWidth, height: 140)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tool = tools[indexPath.item]
        handleToolSelection(tool)
    }
}

// MARK: - Tool Selection
extension FluxToolsViewController {
    private func handleToolSelection(_ tool: ToolItem) {
        switch tool.title {
        case "Custom Themes":
            presentThemesController()
        case "Performance Monitor":
            presentPerformanceMonitor()
        case "Shortcuts":
            presentShortcutsController()
        case "Device Info":
            presentDeviceInfo()
        case "Cache Manager":
            presentCacheManager()
        case "Batch Operations":
            presentBatchOperations()
        case "Backup & Restore":
            presentBackupRestore()
        case "Privacy Settings":
            presentPrivacySettings()
        default:
            break
        }
    }
    
    private func presentThemesController() {
        let themesVC = FluxThemesViewController()
        let navController = UINavigationController(rootViewController: themesVC)
        present(navController, animated: true)
    }
    
    private func presentPerformanceMonitor() {
        let performanceVC = FluxPerformanceViewController()
        let navController = UINavigationController(rootViewController: performanceVC)
        present(navController, animated: true)
    }
    
    private func presentShortcutsController() {
        let shortcutsVC = FluxShortcutsViewController()
        let navController = UINavigationController(rootViewController: shortcutsVC)
        present(navController, animated: true)
    }
    
    private func presentDeviceInfo() {
        let deviceInfoVC = FluxDeviceInfoViewController()
        let navController = UINavigationController(rootViewController: deviceInfoVC)
        present(navController, animated: true)
    }
    
    private func presentCacheManager() {
        let cacheVC = FluxCacheManagerViewController()
        let navController = UINavigationController(rootViewController: cacheVC)
        present(navController, animated: true)
    }
    
    private func presentBatchOperations() {
        let batchVC = FluxBatchOperationsViewController()
        let navController = UINavigationController(rootViewController: batchVC)
        present(navController, animated: true)
    }
    
    private func presentBackupRestore() {
        let backupVC = FluxBackupRestoreViewController()
        let navController = UINavigationController(rootViewController: backupVC)
        present(navController, animated: true)
    }
    
    private func presentPrivacySettings() {
        let privacyVC = FluxPrivacySettingsViewController()
        let navController = UINavigationController(rootViewController: privacyVC)
        present(navController, animated: true)
    }
}

// MARK: - Data Models
struct ToolItem {
    let title: String
    let icon: String
    let description: String
}

// MARK: - Tool Cell
class ToolCell: UICollectionViewCell {
    static let identifier = "ToolCell"
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .altPrimary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .fluxSecondaryText
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.backgroundColor = .fluxCardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.fluxCardBorder.cgColor
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 8
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with tool: ToolItem) {
        titleLabel.text = tool.title
        descriptionLabel.text = tool.description
        iconView.image = UIImage(systemName: tool.icon)
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.contentView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
                self.contentView.alpha = self.isHighlighted ? 0.8 : 1.0
            }
        }
    }
}
