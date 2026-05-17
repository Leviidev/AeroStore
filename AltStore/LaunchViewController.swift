//
//  LaunchViewController.swift
//  AltStore
//

import UIKit
import Roxas
import WidgetKit
import AltSign
import AltStoreCore
import UniformTypeIdentifiers

let pairingFileName = "ALTPairingFile.mobiledevicepairing"

private let aeroPreviewWithoutPairingKey = "AeroStore.previewWithoutDevicePairing"

final class LaunchViewController: UIViewController {
    private var didFinishLaunching = false
    private var retries = 0
    private let maxRetries = 3
    private var splashView: SplashView!
    private var startTime: Date!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        splashView = SplashView(frame: view.bounds, appName: Bundle.main.altAppDisplayName)
        splashView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(splashView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didFinishLaunching else { return }
        startTime = Date()
        Task { @MainActor in
            await runLaunchSequence()
        }
    }

    private func runLaunchSequence() async {
        if retries >= maxRetries {
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

    @MainActor
    private func finishLaunching() async {
        guard !didFinishLaunching else { return }
        didFinishLaunching = true

        let elapsed = abs(startTime.timeIntervalSinceNow)
        let remaining = max(0, 0.25 - elapsed)
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        AppLaunchCoordinator.installMainInterface(animated: true)

        guard let tabBar = AppLaunchCoordinator.resolveKeyWindow()?.rootViewController as? TabBarController else {
            print("❌ LaunchViewController: main interface not installed")
            return
        }

        splashView?.removeFromSuperview()
        runDeferredLaunchWork(on: tabBar)
        schedulePostLaunchWork(on: tabBar)
    }

    @MainActor
    private func schedulePostLaunchWork(on tabBar: TabBarController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SideJITManager.shared.checkAndPromptIfNeeded(presentingVC: tabBar)
            if #available(iOS 17, *), UserDefaults.standard.sidejitenable {
                DispatchQueue.global().async { SideJITManager.shared.askForNetwork() }
            }

            #if !targetEnvironment(simulator)
            self.detectAndImportAccountFile()
            if UserDefaults.standard.enableEMPforWireguard {
                startEMProxy(bind_addr: AppConstants.Proxy.serverURL)
            }
            if let pf = PairingFileManager.shared.fetchPairingFile(presentingVC: tabBar) {
                UserDefaults.standard.set(false, forKey: aeroPreviewWithoutPairingKey)
                PairingFileManager.shared.startMinimuxerIfPossible(pf, presenter: tabBar)
            }
            #endif
        }
    }

    func importAccountAtFile(_ file: URL, remove: Bool = false) {
        _ = file.startAccessingSecurityScopedResource()
        defer { file.stopAccessingSecurityScopedResource() }
        guard let accountD = try? Data(contentsOf: file),
              let account = try? Foundation.JSONDecoder().decode(ImportedAccount.self, from: accountD) else { return }

        if remove { try? FileManager.default.removeItem(at: file) }
        Keychain.shared.appleIDEmailAddress = account.email
        Keychain.shared.appleIDPassword = account.password
        Keychain.shared.adiPb = account.adiPB
        Keychain.shared.identifier = account.local_user
        guard let tabBar = AppLaunchCoordinator.resolveKeyWindow()?.rootViewController as? TabBarController else { return }
        if let altCert = ALTCertificate(p12Data: account.cert, password: account.certpass) {
            Keychain.shared.signingCertificate = altCert.encryptedP12Data(withPassword: "")!
            Keychain.shared.signingCertificatePassword = account.certpass
            ToastView(
                text: NSLocalizedString("Successfully imported '\(account.email)'!", comment: ""),
                detailText: String(format: NSLocalizedString("%@ should be fully operational now.", comment: ""), Bundle.main.altAppDisplayName)
            ).show(in: tabBar)
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
}

extension LaunchViewController {
    @MainActor
    func handleLaunchError(_ error: Error, retryCallback: (() async -> Void)? = nil) {
        do { throw error } catch let error as NSError {
            let title = error.userInfo[NSLocalizedFailureErrorKey] as? String
                ?? String(format: NSLocalizedString("Unable to Launch %@", comment: ""), Bundle.main.altAppDisplayName)
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
            let host = AppLaunchCoordinator.resolveKeyWindow()?.rootViewController ?? self
            host.present(alert, animated: true)
        }
    }

    func runDeferredLaunchWork(on tabBarController: TabBarController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            AppManager.shared.update()
            AppManager.shared.updateAllSources { result in
                guard case .failure(let error) = result else { return }
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
        }
    }

    func updateKnownSources() {
        AppManager.shared.updateKnownSources { result in
            guard case .success((_, let blockedSources)) = result else { return }
            DatabaseManager.shared.persistentContainer.performBackgroundTask { context in
                let blockedSourceIDs = Set(blockedSources.lazy.map { $0.identifier })
                let blockedSourceURLs = Set(blockedSources.lazy.compactMap { $0.sourceURL })
                let predicate = NSPredicate(
                    format: "%K IN %@ OR %K IN %@",
                    #keyPath(Source.identifier), blockedSourceIDs,
                    #keyPath(Source.sourceURL), blockedSourceURLs
                )
                let sourceErrors = Source.all(satisfying: predicate, in: context).map { source in
                    let blocked = blockedSources.first { $0.identifier == source.identifier }
                    return SourceError.blocked(source, bundleIDs: blocked?.bundleIDs, existingSource: source)
                }
                guard !sourceErrors.isEmpty else { return }
                Task { @MainActor in
                    let host = AppLaunchCoordinator.resolveKeyWindow()?.rootViewController
                    for error in sourceErrors {
                        let title = String(format: NSLocalizedString("\"%@\" Blocked", comment: ""), error.$source.name)
                        let message = [error.localizedDescription, error.recoverySuggestion].compactMap { $0 }.joined(separator: "\n\n")
                        await host?.presentAlert(title: title, message: message)
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
            iconView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
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
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}

// MARK: - PairingFileManager
final class PairingFileManager {
    static let shared = PairingFileManager()

    func fetchPairingFile(presentingVC: UIViewController) -> String? {
        let documentsPath = FileManager.default.documentsDirectory.appendingPathComponent(pairingFileName)
        if let contents = try? String(contentsOf: documentsPath), !contents.isEmpty { return contents }
        if let url = Bundle.main.url(forResource: "ALTPairingFile", withExtension: "mobiledevicepairing"),
           let data = try? Data(contentsOf: url),
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
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Browse without pairing", comment: ""), style: .cancel) { _ in
            UserDefaults.standard.set(true, forKey: aeroPreviewWithoutPairingKey)
            ToastView(
                text: NSLocalizedString("Preview mode", comment: ""),
                detailText: NSLocalizedString("Add a pairing file in Settings to install, refresh, or use device features.", comment: "")
            ).show(in: vc)
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
        #if !targetEnvironment(simulator)
        do {
            retargetUsbmuxdAddr()
            let documentsDirectory = FileManager.default.documentsDirectory.absoluteString
            try minimuxerStartWithLogger(pairingString, documentsDirectory, UserDefaults.standard.isMinimuxerConsoleLoggingEnabled)
            startAutoMounter(documentsDirectory)
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

final class PairingFileImportCoordinator: NSObject, UIDocumentPickerDelegate {
    static let shared = PairingFileImportCoordinator()
    weak var presentingViewController: UIViewController?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            guard let pairingString = String(data: data, encoding: .utf8) else { return }
            try pairingString.write(to: FileManager.default.documentsDirectory.appendingPathComponent(pairingFileName), atomically: true, encoding: .utf8)
            UserDefaults.standard.set(false, forKey: aeroPreviewWithoutPairingKey)
            PairingFileManager.shared.startMinimuxerIfPossible(pairingString, presenter: presentingViewController)
        } catch {}
        controller.dismiss(animated: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        UserDefaults.standard.set(true, forKey: aeroPreviewWithoutPairingKey)
    }
}

final class SideJITManager {
    static let shared = SideJITManager()
    func checkAndPromptIfNeeded(presentingVC: UIViewController) {
        guard #available(iOS 17, *), !UserDefaults.standard.sidejitenable else { return }
        DispatchQueue.global().async {
            self.isSideJITServerDetected { result in
                DispatchQueue.main.async {
                    guard case .success = result else { return }
                    let alert = UIAlertController(title: "SideJITServer Detected", message: "Would you like to enable SideJITServer", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in UserDefaults.standard.sidejitenable = true })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    presentingVC.present(alert, animated: true)
                }
            }
        }
    }

    func askForNetwork() {
        let address = UserDefaults.standard.textInputSideJITServerurl ?? ""
        let SJSURL = address.isEmpty ? "http://sidejitserver._http._tcp.local:8080" : address
        URLSession.shared.dataTask(with: URL(string: "\(SJSURL)/re/")!).resume()
    }

    func isSideJITServerDetected(completion: @escaping (Result<Void, Error>) -> Void) {
        let address = UserDefaults.standard.textInputSideJITServerurl ?? ""
        let SJSURL = address.isEmpty ? "http://sidejitserver._http._tcp.local:8080" : address
        guard let url = URL(string: SJSURL) else { return }
        URLSession.shared.dataTask(with: url) { _, _, error in
            if let error { completion(.failure(error)) } else { completion(.success(())) }
        }.resume()
    }
}
