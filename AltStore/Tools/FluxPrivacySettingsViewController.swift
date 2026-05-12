//
//  FluxPrivacySettingsViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024. All rights reserved.
//

import UIKit

class FluxPrivacySettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Privacy Settings", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupViews()
    }
    
    private func setupViews() {
        let label = UILabel()
        label.text = NSLocalizedString("Privacy Settings\n\nManage app permissions and privacy settings for better control over your data.", comment: "")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissPrivacySettings)
        )
    }
    
    @objc private func dismissPrivacySettings() {
        dismiss(animated: true)
    }
}
