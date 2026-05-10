//
//  FluxToastView.swift
//  FluxStore
//
//  Created by FluxStore Team
//  Copyright © 2026 FluxStore. All rights reserved.
//

import UIKit

class FluxToastView: UIView {
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)
    
    private var timer: Timer?
    private var dismissAction: (() -> Void)?
    
    init(notification: FluxNotification) {
        super.init(frame: .zero)
        setupView()
        configure(with: notification)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Container setup
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 16
        containerView.layer.cornerCurve = .continuous
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.15
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        // Icon setup
        containerView.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .fluxPrimary
        
        // Title label setup
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        
        // Message label setup
        containerView.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        
        // Action button setup
        containerView.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        actionButton.setTitleColor(.fluxPrimary, for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        // Dismiss button setup
        addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        dismissButton.tintColor = .secondaryLabel
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        
        setupConstraints()
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(containerTapped))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container constraints
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Icon constraints
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Dismiss button constraints
            dismissButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            dismissButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            dismissButton.widthAnchor.constraint(equalToConstant: 24),
            dismissButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: dismissButton.leadingAnchor, constant: -8),
            
            // Message constraints
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Action button constraints
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
            actionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            actionButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func configure(with notification: FluxNotification) {
        titleLabel.text = notification.title
        messageLabel.text = notification.body
        
        switch notification.category {
        case .appUpdate:
            iconImageView.image = UIImage(systemName: "arrow.down.circle.fill")
            actionButton.setTitle(NSLocalizedString("Update Now", comment: ""), for: .normal)
            
        case .certificateWarning:
            iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            actionButton.setTitle(NSLocalizedString("View Certificate", comment: ""), for: .normal)
            
        case .jitStatus:
            iconImageView.image = UIImage(systemName: "bolt.circle.fill")
            actionButton.setTitle(NSLocalizedString("Manage JIT", comment: ""), for: .normal)
            
        case .system:
            iconImageView.image = UIImage(systemName: "info.circle.fill")
            actionButton.setTitle(NSLocalizedString("Learn More", comment: ""), for: .normal)
        }
    }
    
    func show(duration: TimeInterval = 4.0, completion: (() -> Void)? = nil) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -100)
        
        window.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 16),
            leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16)
        ])
        
        window.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            self.dismiss(completion: completion)
        }
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        timer?.invalidate()
        timer = nil
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -100)
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
    
    @objc private func actionButtonTapped() {
        dismiss()
        // Handle action based on notification type
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController as? TabBarController {
            
            // Navigate based on notification type
            switch titleLabel.text {
            case NSLocalizedString("App Update Available", comment: ""):
                rootViewController.selectedIndex = TabBarController.Tab.myApps.rawValue
            case NSLocalizedString("Certificate Expiring Soon", comment: ""):
                rootViewController.selectedIndex = TabBarController.Tab.settings.rawValue
            default:
                break
            }
        }
    }
    
    @objc private func dismissButtonTapped() {
        dismiss()
    }
    
    @objc private func containerTapped() {
        actionButtonTapped()
    }
}
