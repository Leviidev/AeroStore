//
//  FluxThemesViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024 FluxStore. All rights reserved.
//

import UIKit

class FluxThemesViewController: UIViewController {
    
    private let themes = [
        Theme(name: "Flux Blue", primaryColor: "#007AFF", secondaryColor: "#5856D6", isDefault: true),
        Theme(name: "Sunset Orange", primaryColor: "#FF9500", secondaryColor: "#FF6B00", isDefault: false),
        Theme(name: "Forest Green", primaryColor: "#34C759", secondaryColor: "#30A860", isDefault: false),
        Theme(name: "Royal Purple", primaryColor: "#AF52DE", secondaryColor: "#8E44FF", isDefault: false),
        Theme(name: "Rose Pink", primaryColor: "#FF2D55", secondaryColor: "#FF3B6F", isDefault: false),
        Theme(name: "Ocean Teal", primaryColor: "#5AC8FA", secondaryColor: "#00B4D8", isDefault: false),
        Theme(name: "Monochrome", primaryColor: "#000000", secondaryColor: "#666666", isDefault: false),
        Theme(name: "Custom", primaryColor: "#007AFF", secondaryColor: "#5856D6", isDefault: false, isCustom: true)
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
        cv.register(ThemeCell.self, forCellWithReuseIdentifier: "ThemeCell")
        return cv
    }()
    
    private let currentThemeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Custom Themes", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupCollectionView()
        setupCurrentThemeLabel()
        setupNavigationBar()
        loadCurrentTheme()
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: currentThemeLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCurrentThemeLabel() {
        view.addSubview(currentThemeLabel)
        NSLayoutConstraint.activate([
            currentThemeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            currentThemeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentThemeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissThemes)
        )
    }
    
    private func loadCurrentTheme() {
        let savedThemeName = UserDefaults.standard.string(forKey: "FluxStore.selectedTheme") ?? "Flux Blue"
        currentThemeLabel.text = NSLocalizedString("Current Theme: \(savedThemeName)", comment: "")
    }
    
    @objc private func dismissThemes() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension FluxThemesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThemeCell", for: indexPath) as! ThemeCell
        cell.configure(with: themes[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FluxThemesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 40 // 20 left + 20 right
        let availableWidth = collectionView.frame.width - padding
        let itemWidth = (availableWidth - 16) / 2 // 2 columns with 16pt spacing
        return CGSize(width: itemWidth, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let theme = themes[indexPath.item]
        
        if theme.isCustom {
            presentCustomThemeCreator()
        } else {
            applyTheme(theme)
        }
    }
}

// MARK: - Theme Management
extension FluxThemesViewController {
    private func applyTheme(_ theme: Theme) {
        // Save theme preference
        UserDefaults.standard.set(theme.name, forKey: "FluxStore.selectedTheme")
        
        // Apply colors globally
        UIColor.altPrimary = UIColor(hex: theme.primaryColor)
        UIColor.altSecondary = UIColor(hex: theme.secondaryColor)
        
        // Update UI
        updateCurrentThemeLabel()
        
        // Show confirmation
        let alert = UIAlertController(
            title: NSLocalizedString("Theme Applied", comment: ""),
            message: NSLocalizedString("\(theme.name) theme has been applied successfully.", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
    
    private func presentCustomThemeCreator() {
        let alert = UIAlertController(
            title: NSLocalizedString("Custom Theme", comment: ""),
            message: NSLocalizedString("Create your own custom theme by selecting colors.", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = NSLocalizedString("Primary Color (hex)", comment: "")
            textField.text = "#007AFF"
        }
        
        alert.addTextField { textField in
            textField.placeholder = NSLocalizedString("Secondary Color (hex)", comment: "")
            textField.text = "#5856D6"
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Apply", comment: ""), style: .default) { _ in
            guard let primaryText = alert.textFields?[0].text,
                  let secondaryText = alert.textFields?[1].text else { return }
            
            let customTheme = Theme(
                name: "Custom",
                primaryColor: primaryText,
                secondaryColor: secondaryText,
                isDefault: false,
                isCustom: true
            )
            self.applyTheme(customTheme)
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateCurrentThemeLabel() {
        let savedThemeName = UserDefaults.standard.string(forKey: "FluxStore.selectedTheme") ?? "Flux Blue"
        currentThemeLabel.text = NSLocalizedString("Current Theme: \(savedThemeName)", comment: "")
    }
}

// MARK: - Data Models
struct Theme {
    let name: String
    let primaryColor: String
    let secondaryColor: String
    let isDefault: Bool
    let isCustom: Bool
    
    init(name: String, primaryColor: String, secondaryColor: String, isDefault: Bool, isCustom: Bool = false) {
        self.name = name
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.isDefault = isDefault
        self.isCustom = isCustom
    }
}

// MARK: - Theme Cell
class ThemeCell: UICollectionViewCell {
    static let identifier = "ThemeCell"
    
    private let previewView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var theme: Theme?
    
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
        
        contentView.addSubview(previewView)
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            previewView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            previewView.widthAnchor.constraint(equalToConstant: 50),
            previewView.heightAnchor.constraint(equalToConstant: 30),
            
            nameLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with theme: Theme) {
        self.theme = theme
        nameLabel.text = theme.name
        
        // Create gradient preview
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hex: theme.primaryColor).cgColor,
            UIColor(hex: theme.secondaryColor).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 12
        previewView.layer.addSublayer(gradientLayer)
        
        // Set gradient frame
        layoutIfNeeded()
        gradientLayer.frame = previewView.bounds
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

// MARK: - UIColor Extension
extension UIColor {
    static var altPrimary: UIColor = UIColor(hex: "#007AFF")
    static var altSecondary: UIColor = UIColor(hex: "#5856D6")
    
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            self.init(red: 0, green: 0, blue: 0, alpha: 1)
            return
        }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension Scanner {
    func scanHexInt64(_ result: inout UInt64) -> Bool {
        return scanHexInt64(&result, style: .hex)
    }
}
