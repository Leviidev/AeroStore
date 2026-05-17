//
//  LaunchViewController.swift
//  AltStore
//
//  Created by Riley Testut on 7/30/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import Roxas

import WidgetKit

import AltSign
import AltStoreCore
import UniformTypeIdentifiers

let pairingFileName = "ALTPairingFile.mobiledevicepairing"

/// Set when the user continues without a device pairing file (browse/install blocked until pairing is added).
private let aeroPreviewWithoutPairingKey = "AeroStore.previewWithoutDevicePairing"

final class LaunchViewController: UIViewController {
    private var didFinishLaunching = false
    private var retries = 0
    private var maxRetries = 3
    private var splashView: SplashView!
    private var tabBarController: TabBarController?
    private var startTime: Date!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        splashView = SplashView(frame: view.bounds, appName: Bundle.main.altAppDisplayName)
        view.addSubview(splashView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didFinishLaunching else { return }
        Task { @MainActor in
            startTime = Date()
            await runLaunchSequence()
            doPostLaunch()
        }
    }

    private func runLaunchSequence() async {
        if retries >= maxRetries {
            print("⚠️ Launch sequence exceeded \(maxRetries) retries; showing UI anyway")
            await finishLaunching()
            return
        }
        retries += 1

        if DatabaseManager.shared.isStarted {
            await finishLaunching()
            return
        }

        await withCheckedContinuation { continuation in
            DatabaseManager.shared.start { error in
                Task { @MainActor in
                    if let error {
                        await self.finishLaunching()
                        await self.handleLaunchError(error, retryCallback: self.runLaunchSequence)
                    } else {
                        await self.finishLaunching()
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func doPostLaunch() {
        do {
            print("⏳ Running post-launch tasks...")
            let presenter = self.tabBarController ?? self
            SideJITManager.shared.checkAndPromptIfNeeded(presentingVC: presenter)
            if #available(iOS 17, *), UserDefaults.standard.sidejitenable {
                DispatchQueue.global().async { SideJITManager.shared.askForNetwork() }
                print("SideJITServer Enabled")
            }

            #if !targetEnvironment(simulator)
            
            print("⏳ Detecting account file...")
            detectAndImportAccountFile()
            
            if UserDefaults.standard.enableEMPforWireguard {
                print("⏳ Starting EM Proxy...")
                startEMProxy(bind_addr: AppConstants.Proxy.serverURL)
                print("✅ EM Proxy started")
            }
            if let pf = fetchPairingFile() {
                print("⏳ Pairing file found, starting minimuxer threads...")
                UserDefaults.standard.set(false, forKey: aeroPreviewWithoutPairingKey)
                PairingFileManager.shared.startMinimuxerIfPossible(pf, presenter: tabBarController)
            }
            #endif
            print("✅ Post-launch tasks completed")
        } catch {
            print("❌ Error in doPostLaunch: \(error)")
        }
    }

    func fetchPairingFile() -> String? {
        PairingFileManager.shared.fetchPairingFile(presentingVC: tabBarController ?? self)
    }

    func displayError(_ msg: String) {
        print(msg)
        let alert = UIAlertController(
            title: String(format: NSLocalizedString("Error launching %@", comment: ""), Bundle.main.altAppDisplayName),
            message: msg,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        (self.tabBarController ?? self).present(alert, animated: true)
    }

    func importAccountAtFile(_ file: URL, remove: Bool = false) {
        _ = file.startAccessingSecurityScopedResource()
        defer { file.stopAccessingSecurityScopedResource() }
        guard let accountD = try? Data(contentsOf: file) else {
            return Logger.main.notice("Could not parse data from file \(file)")
        }
        guard let account = try? Foundation.JSONDecoder().decode(ImportedAccount.self, from: accountD) else {
            return Logger.main.notice("Could not parse data from file \(file)")
        }
        print("We want to import this account probably: \(account)")
        if remove {
            try? FileManager.default.removeItem(at: file)
        }
        Keychain.shared.appleIDEmailAddress = account.email
        Keychain.shared.appleIDPassword = account.password
        Keychain.shared.adiPb = account.adiPB
        Keychain.shared.identifier = account.local_user
        if let altCert = ALTCertificate(p12Data: account.cert, password: account.certpass) {
            Keychain.shared.signingCertificate = altCert.encryptedP12Data(withPassword: "")!
            Keychain.shared.signingCertificatePassword = account.certpass
            let toastView = ToastView(text: NSLocalizedString("Successfully imported '\(account.email)'!", comment: ""), detailText: String(format: NSLocalizedString("%@ should be fully operational now.", comment: ""), Bundle.main.altAppDisplayName))
            return toastView.show(in: self.tabBarController ?? self)
        } else {
            let toastView = ToastView(text: NSLocalizedString("Failed to import account certificate!", comment: ""), detailText: NSLocalizedString("Failed to create ALTCertificate. Check if the password is correct.", comment: ""))
            return toastView.show(in: self.tabBarController ?? self)
        }
    }
    
    func detectAndImportAccountFile() {
        let accountFileURL = FileManager.default.documentsDirectory.appendingPathComponent("Account.sideconf")
        #if !DEBUG
        importAccountAtFile(accountFileURL, remove: true)
        #else
        importAccountAtFile(accountFileURL)
        #endif
    }
    
    private func handleFatalError(_ error: Error) {
        print("🔴 FATAL ERROR: \(error)")
        print("Stack trace: \(Thread.callStackSymbols)")
    }
}

extension LaunchViewController {
    @MainActor
    func handleLaunchError(_ error: Error, retryCallback: (() async -> Void)? = nil) {
        do { throw error } catch let error as NSError {
            let title = error.userInfo[NSLocalizedFailureErrorKey] as? String ?? String(format: NSLocalizedString("Unable to Launch %@", comment: ""), Bundle.main.altAppDisplayName)
            let desc: String
            if #available(iOS 14.5, *) {
                desc = ([error.debugDescription] + error.underlyingErrors.map { ($0 as NSError).debugDescription }).joined(separator: "\n\n")
            } else {
                desc = error.debugDescription
            }
            let alert = UIAlertController(title: title, message: desc, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default) { _ in
                Task { await retryCallback?() }
            })
            (tabBarController ?? self).present(alert, animated: true)
        }
    }

    @MainActor
    private func makeTabBarController() -> TabBarController? {
        if let tabBarController {
            return tabBarController
        }
        let storyboard = storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "tabBarController") as? TabBarController
        tabBarController = controller
        return controller
    }

    @MainActor
    func finishLaunching() async {
        guard !didFinishLaunching else { return }
        didFinishLaunching = true

        guard let destinationVC = makeTabBarController() else {
            displayError(NSLocalizedString("Could not load the main interface.", comment: ""))
            return
        }

        if startTime == nil { startTime = Date() }

        let elapsed = abs(startTime.timeIntervalSinceNow)
        let remaining = max(0, 0.35 - elapsed)
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        destinationVC.loadViewIfNeeded()

        if let window = view.window ?? Self.activeWindow {
            window.backgroundColor = .systemBackground
            window.rootViewController = destinationVC
            window.makeKeyAndVisible()
            FluxAppearancePreference.applyToAllWindows()
            splashView.removeFromSuperview()
            runDeferredLaunchWork(on: destinationVC)
            return
        }

        // Fallback if the scene window is not wired yet.
        addChild(destinationVC)
        destinationVC.view.frame = view.bounds
        destinationVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(destinationVC.view, belowSubview: splashView)
        destinationVC.didMove(toParent: self)
        splashView.removeFromSuperview()
        runDeferredLaunchWork(on: destinationVC)
    }

    private static var activeWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    func runDeferredLaunchWork(on tabBarController: TabBarController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            do {
                print("⏳ Running deferred launch work...")
                AppManager.shared.update()
                AppManager.shared.updateAllSources { result in
                    guard case .failure(let error) = result else {
                        print("✅ Sources updated successfully")
                        return
                    }
                    print("❌ Failed to update sources on launch: \(error.localizedDescription)")
                    Logger.main.error("Failed to update sources on launch. \(error.localizedDescription, privacy: .public)")

                    let errorDesc = ErrorProcessing(.fullError).getDescription(error: error as NSError)
                    print("Failed to update sources on launch. \(errorDesc)")

                    var mode: ToastView.InfoMode = .fullError
                    if String(describing: error).contains("The Internet connection appears to be offline") {
                        mode = .localizedDescription
                    }

                    let toastView = ToastView(error: error, mode: mode)
                    toastView.addTarget(tabBarController, action: #selector(TabBarController.presentSources), for: .touchUpInside)

                    toastView.show(in: tabBarController.selectedViewController ?? tabBarController)
                }

                self.updateKnownSources()
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("❌ Error in runDeferredLaunchWork: \(error)")
            }
        }
    }

    func updateKnownSources() {
        AppManager.shared.updateKnownSources { result in
            switch result {
            case .failure(let error):
                print("❌ Failed to update known sources: \(error)")
            case .success((_, let blockedSources)):
                DatabaseManager.shared.persistentContainer.performBackgroundTask { context in
                    let blockedSourceIDs = Set(blockedSources.lazy.map { $0.identifier })
                    let blockedSourceURLs = Set(blockedSources.lazy.compactMap { $0.sourceURL })
                    let predicate = NSPredicate(format: "%K IN %@ OR %K IN %@", #keyPath(Source.identifier), blockedSourceIDs, #keyPath(Source.sourceURL), blockedSourceURLs)
                    let sourceErrors = Source.all(satisfying: predicate, in: context).map { source in
                        let blocked = blockedSources.first { $0.identifier == source.identifier }
                        return SourceError.blocked(source, bundleIDs: blocked?.bundleIDs, existingSource: source)
                    }
                    guard !sourceErrors.isEmpty else { return }
                    Task {
                        for error in sourceErrors {
                            let title = String(format: NSLocalizedString("\"%@\" Blocked", comment: ""), error.$source.name)
                            let message = [error.localizedDescription, error.recoverySuggestion].compactMap { $0 }.joined(separator: "\n\n")
                            await self.presentAlert(title: title, message: message)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SplashView
final class SplashView: UIView {
    let iconView = AeroLogoView()
    let titleLabel = UILabel()

    init(frame: CGRect, appName: String) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupIcon()
        setupTitle(appName: appName)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupIcon() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.18
        container.layer.shadowOffset = CGSize(width: 0, height: 6)
        container.layer.shadowRadius = 14
        addSubview(container)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 28
        iconView.clipsToBounds = true
        container.addSubview(iconView)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -24),
            container.widthAnchor.constraint(equalToConstant: 128),
            container.heightAnchor.constraint(equalToConstant: 128),
            iconView.topAnchor.constraint(equalTo: container.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
    }

    private func setupTitle(appName: String) {
        titleLabel.text = appName
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}

// MARK: - PairingFileManager
final class PairingFileManager {
    static let shared = PairingFileManager()
    func fetchPairingFile(presentingVC: UIViewController) -> String? {
        let fm = FileManager.default
        let filename = pairingFileName
        let documentsPath = fm.documentsDirectory.appendingPathComponent("/\(filename)")
        if fm.fileExists(atPath: documentsPath.path),
           let contents = try? String(contentsOf: documentsPath), !contents.isEmpty {
            return contents
        }
        if let url = Bundle.main.url(forResource: "ALTPairingFile", withExtension: "mobiledevicepairing"),
           fm.fileExists(atPath: url.path),
           let data = fm.contents(atPath: url.path),
           let contents = String(data: data, encoding: .utf8),
           !contents.isEmpty, !UserDefaults.standard.isPairingReset { return contents }
        if let plistString = Bundle.main.object(forInfoDictionaryKey: "ALTPairingFile") as? String,
           !plistString.isEmpty, !plistString.contains("insert pairing file here"), !UserDefaults.standard.isPairingReset { return plistString }

        presentPairingFileAlert(on: presentingVC)
        return nil
    }

    private func presentPairingFileAlert(on vc: UIViewController) {
        let alert = UIAlertController(
            title: NSLocalizedString("Pairing File", comment: ""),
            message: String(
                format: NSLocalizedString("Import a pairing file to refresh and install apps in %@. You can skip for now to browse sources only.", comment: ""),
                Bundle.main.altAppDisplayName
            ),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Help", comment: ""), style: .default) { _ in
            if let url = URL(string: "https://docs.sidestore.io/docs/advanced/pairing-file") { UIApplication.shared.open(url) }
            sleep(2); exit(0)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Browse without pairing", comment: ""), style: .cancel) { _ in
            UserDefaults.standard.set(true, forKey: aeroPreviewWithoutPairingKey)
            let toast = ToastView(
                text: NSLocalizedString("Preview mode", comment: ""),
                detailText: NSLocalizedString("Add a pairing file in Settings to install, refresh, or use device features.", comment: "")
            )
            toast.show(in: vc)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Choose File…", comment: ""), style: .default) { _ in
            var types = UTType.types(tag: "plist", tagClass: .filenameExtension, conformingTo: nil)
            types.append(contentsOf: UTType.types(tag: "mobiledevicepairing", tagClass: .filenameExtension, conformingTo: .data))
            types.append(.xml)
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
            picker.delegate = PairingFileImportCoordinator.shared
            PairingFileImportCoordinator.shared.presentingViewController = vc
            picker.shouldShowFileExtensions = true
            vc.present(picker, animated: true)
            UserDefaults.standard.isPairingReset = false
        })
        vc.present(alert, animated: true)
    }

    func startMinimuxerIfPossible(_ pairingString: String, presenter: UIViewController?) {
        #if targetEnvironment(simulator)
        return
        #else
        do {
            retargetUsbmuxdAddr()
            let documentsDirectory = FileManager.default.documentsDirectory.absoluteString
            let loggingEnabled = UserDefaults.standard.isMinimuxerConsoleLoggingEnabled
            try minimuxerStartWithLogger(pairingString, documentsDirectory, loggingEnabled)
            let documentsDirectoryPath = FileManager.default.documentsDirectory.absoluteString
            startAutoMounter(documentsDirectoryPath)
        } catch {
            try? FileManager.default.removeItem(at: FileManager.default.documentsDirectory.appendingPathComponent(pairingFileName))
            guard let presenter else { return }
            let alert = UIAlertController(
                title: String(format: NSLocalizedString("Error launching %@", comment: ""), Bundle.main.altAppDisplayName),
                message: (error as? LocalizedError)?.failureReason ?? error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            presenter.present(alert, animated: true)
        }
        #endif
    }
}

// MARK: - Pairing file import (survives launch → tab bar transition)
final class PairingFileImportCoordinator: NSObject, UIDocumentPickerDelegate {
    static let shared = PairingFileImportCoordinator()
    weak var presentingViewController: UIViewController?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let isSecuredURL = url.startAccessingSecurityScopedResource()
        defer {
            if isSecuredURL { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let data = try Data(contentsOf: url)
            guard let pairingString = String(data: data, encoding: .utf8) else {
                showError(NSLocalizedString("Unable to read pairing file", comment: ""))
                return
            }
            try pairingString.write(
                to: FileManager.default.documentsDirectory.appendingPathComponent(pairingFileName),
                atomically: true,
                encoding: .utf8
            )
            UserDefaults.standard.set(false, forKey: aeroPreviewWithoutPairingKey)
            PairingFileManager.shared.startMinimuxerIfPossible(pairingString, presenter: presentingViewController)
        } catch {
            showError(NSLocalizedString("Unable to read pairing file", comment: ""))
        }

        controller.dismiss(animated: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        UserDefaults.standard.set(true, forKey: aeroPreviewWithoutPairingKey)
        guard let host = presentingViewController else { return }
        let toast = ToastView(
            text: NSLocalizedString("Browsing without pairing", comment: ""),
            detailText: NSLocalizedString("Add a pairing file in Settings when you're ready to install, refresh, or use device features.", comment: "")
        )
        toast.show(in: host)
    }

    private func showError(_ message: String) {
        guard let host = presentingViewController else { return }
        let alert = UIAlertController(
            title: String(format: NSLocalizedString("Error launching %@", comment: ""), Bundle.main.altAppDisplayName),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        host.present(alert, animated: true)
    }
}

// MARK: - SideJITManager
final class SideJITManager {
    static let shared = SideJITManager()
    func checkAndPromptIfNeeded(presentingVC: UIViewController) {
        guard #available(iOS 17, *), !UserDefaults.standard.sidejitenable else { return }
        DispatchQueue.global().async {
            self.isSideJITServerDetected { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        let alert = UIAlertController(title: "SideJITServer Detected", message: "Would you like to enable SideJITServer", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in UserDefaults.standard.sidejitenable = true })
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        presentingVC.present(alert, animated: true)
                    case .failure(_): print("Cannot find sideJITServer")
                    }
                }
            }
        }
    }

    func askForNetwork() {
        let address = UserDefaults.standard.textInputSideJITServerurl ?? ""
        let SJSURL = address.isEmpty ? "http://sidejitserver._http._tcp.local:8080" : address
        URLSession.shared.dataTask(with: URL(string: "\(SJSURL)/re/")!) { data, resp, err in
            print("data: \(String(describing: data)), response: \(String(describing: resp)), error: \(String(describing: err))")
        }.resume()
    }

    func isSideJITServerDetected(completion: @escaping (Result<Void, Error>) -> Void) {
        let address = UserDefaults.standard.textInputSideJITServerurl ?? ""
        let SJSURL = address.isEmpty ? "http://sidejitserver._http._tcp.local:8080" : address
        guard let url = URL(string: SJSURL) else { return }
        URLSession.shared.dataTask(with: url) { _, _, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }
}
