//
//  FluxBackupRestoreViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024. All rights reserved.
//

import UIKit

class FluxBackupRestoreViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Backup & Restore", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupViews()
    }
    
    private func setupViews() {
        let label = UILabel()
        label.text = NSLocalizedString("Backup & Restore\n\nBackup your app configurations and restore them when needed.", comment: "")
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
            action: #selector(dismissBackupRestore)
        )
    }
    
    @objc private func dismissBackupRestore() {
        dismiss(animated: true)
    }
}
