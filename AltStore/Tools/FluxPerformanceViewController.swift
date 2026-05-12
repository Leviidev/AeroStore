//
//  FluxPerformanceViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024 FluxStore. All rights reserved.
//

import UIKit

class FluxPerformanceViewController: UIViewController {
    
    private let performanceMetrics = [
        PerformanceMetric(title: "CPU Usage", icon: "cpu", value: "0%", color: .systemGreen),
        PerformanceMetric(title: "Memory Usage", icon: "memorychip", value: "0 MB", color: .systemBlue),
        PerformanceMetric(title: "Storage Space", icon: "internaldrive", value: "0 GB", color: .systemOrange),
        PerformanceMetric(title: "Network Speed", icon: "network", value: "0 Mbps", color: .systemPurple),
        PerformanceMetric(title: "Battery Level", icon: "battery.100", value: "0%", color: .systemGreen),
        PerformanceMetric(title: "App Launch Time", icon: "timer", value: "0.0s", color: .systemRed)
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
        cv.register(PerformanceCell.self, forCellWithReuseIdentifier: "PerformanceCell")
        return cv
    }()
    
    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Refresh", comment: ""), for: .normal)
        button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        button.backgroundColor = .altPrimary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .altPrimary
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var refreshTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Performance Monitor", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupViews()
        setupNavigationBar()
        startPerformanceMonitoring()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func setupViews() {
        view.addSubview(collectionView)
        view.addSubview(refreshButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: refreshButton.topAnchor, constant: -20),
            
            refreshButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            refreshButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        refreshButton.addTarget(self, action: #selector(refreshPerformanceMetrics), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissPerformance)
        )
    }
    
    private func startPerformanceMonitoring() {
        refreshPerformanceMetrics()
        
        // Update metrics every 5 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.refreshPerformanceMetrics()
        }
    }
    
    @objc private func refreshPerformanceMetrics() {
        activityIndicator.startAnimating()
        refreshButton.isEnabled = false
        
        // Simulate performance data collection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updatePerformanceData()
            self.activityIndicator.stopAnimating()
            self.refreshButton.isEnabled = true
        }
    }
    
    private func updatePerformanceData() {
        // Update with simulated real-time data
        var updatedMetrics = performanceMetrics
        
        // CPU Usage (0-100%)
        let cpuUsage = Double.random(in: 5...45)
        updatedMetrics[0].value = String(format: "%.1f%%", cpuUsage)
        updatedMetrics[0].color = cpuUsage > 30 ? .systemRed : (cpuUsage > 20 ? .systemYellow : .systemGreen)
        
        // Memory Usage (0-8GB)
        let memoryUsage = Double.random(in: 1.5...4.5)
        updatedMetrics[1].value = String(format: "%.1f MB", memoryUsage * 1024)
        updatedMetrics[1].color = memoryUsage > 3.5 ? .systemRed : (memoryUsage > 2.5 ? .systemYellow : .systemGreen)
        
        // Storage Space
        let totalSpace = Double.random(in: 50...200)
        let usedSpace = totalSpace * Double.random(in: 0.3...0.8)
        updatedMetrics[2].value = String(format: "%.1f GB", totalSpace - usedSpace)
        updatedMetrics[2].color = (totalSpace - usedSpace) < 20 ? .systemRed : (totalSpace - usedSpace) < 50 ? .systemYellow : .systemGreen)
        
        // Network Speed
        let networkSpeed = Double.random(in: 5...100)
        updatedMetrics[3].value = String(format: "%.0f Mbps", networkSpeed)
        updatedMetrics[3].color = networkSpeed > 50 ? .systemGreen : (networkSpeed > 20 ? .systemYellow : .systemRed)
        
        // Battery Level
        let batteryLevel = Double.random(in: 20...100)
        updatedMetrics[4].value = String(format: "%.0f%%", batteryLevel)
        updatedMetrics[4].icon = batteryLevel > 20 ? "battery.100" : "battery.25"
        updatedMetrics[4].color = batteryLevel > 50 ? .systemGreen : (batteryLevel > 20 ? .systemYellow : .systemRed)
        
        // App Launch Time
        let launchTime = Double.random(in: 0.5...3.0)
        updatedMetrics[5].value = String(format: "%.1fs", launchTime)
        updatedMetrics[5].color = launchTime < 1.0 ? .systemGreen : (launchTime < 2.0 ? .systemYellow : .systemRed)
        
        // Update collection view
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc private func dismissPerformance() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension FluxPerformanceViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return performanceMetrics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PerformanceCell", for: indexPath) as! PerformanceCell
        cell.configure(with: performanceMetrics[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FluxPerformanceViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 40 // 20 left + 20 right
        let availableWidth = collectionView.frame.width - padding
        let itemWidth = (availableWidth - 16) / 2 // 2 columns with 16pt spacing
        return CGSize(width: itemWidth, height: 120)
    }
}

// MARK: - Data Models
struct PerformanceMetric {
    let title: String
    let icon: String
    var value: String
    var color: UIColor
    
    init(title: String, icon: String, value: String, color: UIColor) {
        self.title = title
        self.icon = icon
        self.value = value
        self.color = color
    }
}

// MARK: - Performance Cell
class PerformanceCell: UICollectionViewCell {
    static let identifier = "PerformanceCell"
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
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
        contentView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with metric: PerformanceMetric) {
        titleLabel.text = metric.title
        valueLabel.text = metric.value
        valueLabel.textColor = metric.color
        iconView.image = UIImage(systemName: metric.icon)
        iconView.tintColor = metric.color
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
