//
//  FluxDeviceInfoViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024 FluxStore. All rights reserved.
//

import UIKit
import SystemConfiguration

class FluxDeviceInfoViewController: UIViewController {
    
    private var deviceInfo: [DeviceInfoItem] = []
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .altBackground
        tv.delegate = self
        tv.dataSource = self
        tv.register(DeviceInfoCell.self, forCellReuseIdentifier: "DeviceInfoCell")
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        return tv
    }()
    
    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Refresh Info", comment: ""), for: .normal)
        button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        button.backgroundColor = .altPrimary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Device Info", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupDeviceInfo()
        setupViews()
        setupNavigationBar()
    }
    
    private func setupDeviceInfo() {
        deviceInfo = [
            DeviceInfoItem(title: "Device Name", value: UIDevice.current.name),
            DeviceInfoItem(title: "Model", value: getDeviceModel()),
            DeviceInfoItem(title: "iOS Version", value: UIDevice.current.systemVersion),
            DeviceInfoItem(title: "App Version", value: getAppVersion()),
            DeviceInfoItem(title: "Build Number", value: getBuildNumber()),
            DeviceInfoItem(title: "Storage Total", value: getTotalStorage()),
            DeviceInfoItem(title: "Storage Available", value: getAvailableStorage()),
            DeviceInfoItem(title: "Battery Level", value: getBatteryLevel()),
            DeviceInfoItem(title: "Jailbreak Status", value: isJailbroken() ? "Jailbroken" : "Not Jailbroken"),
            DeviceInfoItem(title: "FluxStore ID", value: getFluxStoreID()),
            DeviceInfoItem(title: "Network Status", value: getNetworkStatus())
        ]
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(refreshButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: refreshButton.topAnchor, constant: -20),
            
            refreshButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            refreshButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        refreshButton.addTarget(self, action: #selector(refreshDeviceInfo), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissDeviceInfo)
        )
    }
    
    @objc private func refreshDeviceInfo() {
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Refresh with animation
        UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve) {
            self.tableView.reloadData()
        }
    }
    
    @objc private func dismissDeviceInfo() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FluxDeviceInfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceInfoCell", for: indexPath) as! DeviceInfoCell
        cell.configure(with: deviceInfo[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FluxDeviceInfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = deviceInfo[indexPath.row]
        copyToClipboard(item.value)
        
        // Show confirmation
        let alert = UIAlertController(
            title: NSLocalizedString("Copied", comment: ""),
            message: NSLocalizedString("\(item.title) copied to clipboard", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Device Info Utilities
extension FluxDeviceInfoViewController {
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                ptr in String(cString: ptr)
            }
        }
        
        let modelMap: [String: String] = [
            "i386": "Simulator", "x86_64": "Simulator",
            "iPhone1,1": "iPhone", "iPhone1,2": "iPhone 3G",
            "iPhone2,1": "iPhone 3GS", "iPhone3,1": "iPhone 4",
            "iPhone3,2": "iPhone 4", "iPhone3,3": "iPhone 4",
            "iPhone4,1": "iPhone 4S", "iPhone5,1": "iPhone 5",
            "iPhone5,2": "iPhone 5", "iPhone5,3": "iPhone 5c",
            "iPhone5,4": "iPhone 5s", "iPhone6,1": "iPhone 5s",
            "iPhone6,2": "iPhone 6", "iPhone7,1": "iPhone 6 Plus",
            "iPhone7,2": "iPhone 6", "iPhone8,1": "iPhone 6s",
            "iPhone8,2": "iPhone 6s Plus", "iPhone8,4": "iPhone SE",
            "iPhone9,1": "iPhone 7", "iPhone9,2": "iPhone 7 Plus",
            "iPhone9,3": "iPhone 7", "iPhone9,4": "iPhone 7 Plus",
            "iPhone10,1": "iPhone 8", "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,3": "iPhone X", "iPhone10,4": "iPhone X",
            "iPhone10,5": "iPhone 8", "iPhone10,6": "iPhone 8 Plus",
            "iPhone11,2": "iPhone XS", "iPhone11,4": "iPhone XS Max",
            "iPhone11,6": "iPhone XR", "iPhone11,8": "iPhone XS",
            "iPhone12,1": "iPhone 11 Pro", "iPhone12,3": "iPhone 11 Pro Max",
            "iPhone12,5": "iPhone 11", "iPhone12,8": "iPhone 11 Pro",
            "iPhone13,1": "iPhone 12 mini", "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone14,2": "iPhone 13 mini", "iPhone14,3": "iPhone 13",
            "iPhone14,4": "iPhone 13 Pro", "iPhone14,5": "iPhone 13 Pro Max",
            "iPhone14,6": "iPhone SE (3rd gen)", "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus", "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max", "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus", "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max"
        ]
        
        return modelMap[modelCode] ?? modelCode
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private func getTotalStorage() -> String {
        guard let space = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[.systemSize] else {
            return "Unknown"
        }
        let bytes = space as! Int64
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    private func getAvailableStorage() -> String {
        guard let space = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[.systemFreeSize] else {
            return "Unknown"
        }
        let bytes = space as! Int64
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    private func getBatteryLevel() -> String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel < 0 {
            return "Unknown"
        }
        return String(format: "%.0f%%", batteryLevel * 100)
    }
    
    private func isJailbroken() -> Bool {
        return FileManager.default.fileExists(atPath: "/Applications/Cydia.app") ||
               FileManager.default.fileExists(atPath: "/private/var/lib/apt")
    }
    
    private func getFluxStoreID() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }
    
    private func getNetworkStatus() -> String {
        guard let reachability = try? Reachability(hostname: "google.com") else {
            return "Unknown"
        }
        
        switch reachability.connection {
        case .wifi:
            return "WiFi Connected"
        case .cellular:
            return "Cellular Connected"
        case .unavailable:
            return "No Connection"
        default:
            return "Unknown"
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Data Models
struct DeviceInfoItem {
    let title: String
    let value: String
}

// MARK: - Device Info Cell
class DeviceInfoCell: UITableViewCell {
    static let identifier = "DeviceInfoCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .fluxSecondaryText
        label.textAlignment = .right
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .fluxCardBackground
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 20),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with item: DeviceInfoItem) {
        titleLabel.text = item.title
        valueLabel.text = item.value
    }
}

// MARK: - Reachability (simplified)
class Reachability {
    enum Connection {
        case wifi, cellular, unavailable
    }
    
    var connection: Connection = .unavailable
    
    init?(hostname: String) throws {
        // Simplified reachability check
        self.connection = .wifi // Default to WiFi for demo
    }
}
