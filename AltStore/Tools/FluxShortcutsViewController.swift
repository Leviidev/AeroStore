//
//  FluxShortcutsViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024 FluxStore. All rights reserved.
//

import UIKit
import Intents
import IntentsUI
import SafariServices

class FluxShortcutsViewController: UIViewController {
    
    private let shortcuts = [
        ShortcutItem(
            title: "Install App",
            description: "Quickly install an app from URL",
            icon: "square.and.arrow.down.fill",
            intent: InstallAppIntent()
        ),
        ShortcutItem(
            title: "Refresh All Apps",
            description: "Refresh all installed apps",
            icon: "arrow.clockwise",
            intent: RefreshAppsIntent()
        ),
        ShortcutItem(
            title: "Open FluxStore",
            description: "Open FluxStore app",
            icon: "app.fill",
            intent: OpenFluxStoreIntent()
        ),
        ShortcutItem(
            title: "Check Updates",
            description: "Check for app updates",
            icon: "newspaper.fill",
            intent: CheckUpdatesIntent()
        ),
        ShortcutItem(
            title: "Clear Cache",
            description: "Clear app cache and temporary files",
            icon: "trash.fill",
            intent: ClearCacheIntent()
        ),
        ShortcutItem(
            title: "Toggle Theme",
            description: "Switch between light and dark themes",
            icon: "paintbrush.fill",
            intent: ToggleThemeIntent()
        )
    ]
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .altBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(ShortcutCell.self, forCellWithReuseIdentifier: "ShortcutCell")
        return cv
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .fluxSecondaryText
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = NSLocalizedString("Create Siri shortcuts for common FluxStore actions. Tap any shortcut below to add it to Siri.", comment: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Shortcuts", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupViews()
        setupNavigationBar()
    }
    
    private func setupViews() {
        view.addSubview(infoLabel)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            collectionView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissShortcuts)
        )
    }
    
    @objc private func dismissShortcuts() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension FluxShortcutsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shortcuts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortcutCell", for: indexPath) as! ShortcutCell
        cell.configure(with: shortcuts[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FluxShortcutsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 40 // 20 left + 20 right
        let availableWidth = collectionView.frame.width - padding
        let itemWidth = (availableWidth - 16) / 2 // 2 columns with 16pt spacing
        return CGSize(width: itemWidth, height: 140)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let shortcut = shortcuts[indexPath.item]
        presentShortcutCreator(for: shortcut)
    }
}

// MARK: - Shortcut Management
extension FluxShortcutsViewController {
    private func presentShortcutCreator(for shortcut: ShortcutItem) {
        let intent = shortcut.intent
        
        if #available(iOS 12.0, *) {
            let shortcut = INShortcut(intent: intent)
            let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
            viewController.delegate = self
            
            present(viewController, animated: true)
        } else {
            // Fallback for older iOS versions
            let alert = UIAlertController(
                title: NSLocalizedString("Shortcuts Not Available", comment: ""),
                message: NSLocalizedString("Siri shortcuts require iOS 12 or later.", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - INUIAddVoiceShortcutViewControllerDelegate
extension FluxShortcutsViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith error: Error?) {
        controller.dismiss(animated: true) {
            if let error = error {
                self.showShortcutError(error)
            } else {
                self.showShortcutSuccess()
            }
        }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
    
    private func showShortcutSuccess() {
        let alert = UIAlertController(
            title: NSLocalizedString("Shortcut Added", comment: ""),
            message: NSLocalizedString("Siri shortcut has been added successfully!", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
    
    private func showShortcutError(_ error: Error) {
        let alert = UIAlertController(
            title: NSLocalizedString("Error", comment: ""),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Data Models
struct ShortcutItem {
    let title: String
    let description: String
    let icon: String
    let intent: INIntent
    
    init(title: String, description: String, icon: String, intent: INIntent) {
        self.title = title
        self.description = description
        self.icon = icon
        self.intent = intent
    }
}

// MARK: - Shortcut Cell
class ShortcutCell: UICollectionViewCell {
    static let identifier = "ShortcutCell"
    
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
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .fluxSecondaryText
        label.numberOfLines = 2
        label.textAlignment = .center
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
            
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with shortcut: ShortcutItem) {
        titleLabel.text = shortcut.title
        descriptionLabel.text = shortcut.description
        iconView.image = UIImage(systemName: shortcut.icon)
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

// MARK: - Intent Definitions (simplified for example)
class InstallAppIntent: INIntent {}
class RefreshAppsIntent: INIntent {}
class OpenFluxStoreIntent: INIntent {}
class CheckUpdatesIntent: INIntent {}
class ClearCacheIntent: INIntent {}
class ToggleThemeIntent: INIntent {}
