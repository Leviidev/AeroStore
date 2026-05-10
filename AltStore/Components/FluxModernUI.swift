//
//  FluxModernUI.swift
//  FluxStore
//
//  Created by FluxStore Team
//  Copyright © 2026 FluxStore. All rights reserved.
//

import UIKit

// MARK: - Modern UI Extensions
extension UIColor {
    static let fluxPrimary = UIColor.systemBlue
    static let fluxSecondary = UIColor.systemPurple
    static let fluxAccent = UIColor.systemIndigo
    
    // Modern gradient colors
    static let fluxGradientStart = UIColor.systemBackground
    static let fluxGradientEnd = UIColor.secondarySystemBackground
}

// MARK: - Modern View Protocol
protocol FluxModernView {
    func applyModernStyle()
}

extension FluxModernView where Self: UIView {
    func applyModernStyle() {
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        
        // Update shadow path for better performance
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
}

// MARK: - Modern Button Styles
extension UIButton {
    func applyFluxModernStyle(style: FluxButtonStyle = .primary) {
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)
        
        switch style {
        case .primary:
            backgroundColor = .fluxPrimary
            setTitleColor(.white, for: .normal)
            titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            
        case .secondary:
            backgroundColor = .secondarySystemBackground
            setTitleColor(.label, for: .normal)
            titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            
        case .accent:
            backgroundColor = .fluxAccent
            setTitleColor(.white, for: .normal)
            titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        }
    }
}

enum FluxButtonStyle {
    case primary
    case secondary
    case accent
}

// MARK: - Modern Card View
class FluxCardView: UIView, FluxModernView {
    private let containerView = UIView()
    private let contentView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        applyModernStyle()
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        // Add subtle gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.fluxGradientStart.withAlphaComponent(0.95).cgColor,
            UIColor.fluxGradientEnd.withAlphaComponent(0.85).cgColor
        ]
        gradientLayer.cornerRadius = layer.cornerRadius
        gradientLayer.frame = bounds
        gradientLayer.masksToBounds = true
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func addContentView(_ view: UIView) {
        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient layer frame
        if let gradientLayer = layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bounds
            gradientLayer.cornerRadius = layer.cornerRadius
        }
        
        // Update shadow path
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
}

// MARK: - Modern Navigation Controller
extension UINavigationController {
    func applyFluxModernStyle() {
        navigationBar.prefersLargeTitles = true
        navigationBar.backgroundColor = .systemBackground
        navigationBar.isTranslucent = false
        
        // Modern appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
}

// MARK: - Modern Table View Cell
class FluxModernTableViewCell: UITableViewCell, FluxModernView {
    private let cardView = FluxCardView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func addCustomContentView(_ view: UIView) {
        cardView.addContentView(view)
    }
}

// MARK: - Modern Collection View Cell
class FluxModernCollectionViewCell: UICollectionViewCell, FluxModernView {
    private let cardView = FluxCardView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func addCustomContentView(_ view: UIView) {
        cardView.addContentView(view)
    }
}

// MARK: - Modern Animation Helpers
extension UIView {
    func animateFluxSpring(duration: TimeInterval = 0.6, delay: TimeInterval = 0, animations: @escaping () -> Void) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: animations)
    }
    
    func animateFluxFadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        alpha = 0
        animateFluxSpring(duration: duration, delay: delay) {
            self.alpha = 1
        }
    }
    
    func animateFluxScaleIn(duration: TimeInterval = 0.4, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        alpha = 0
        animateFluxSpring(duration: duration, delay: delay) {
            self.transform = .identity
            self.alpha = 1
        }
    }
}
