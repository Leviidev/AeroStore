//
//  FluxJITRootView.swift
//  FluxStore
//

import SwiftUI
import UIKit

struct FluxJITRootView: View {
    var body: some View {
        InstalledAppsListView(
            onSelectApp: { bundleID in
                HapticFeedbackHelper.trigger()
                DispatchQueue.global(qos: .background).async {
                    let keepAlive = FluxDebugKeepAliveLease()
                    defer { keepAlive.invalidate() }
                    let logger: LogFunc = { message in
                        if let message {
                            LogManager.shared.addInfoLog(message)
                        }
                    }
                    _ = JITEnableContext.shared.debugApp(withBundleID: bundleID, logger: logger, jsCallback: nil)
                }
            },
            showDoneButton: true,
            onImportPairingFile: nil
        )
        .onAppear {
            startTunnelInBackground()
            MountingProgress.shared.checkforMounted()
            FluxStikJITHostBootstrap.ensureDeveloperDiskImagesPresent()
        }
    }
}

private final class FluxDebugKeepAliveLease {
    private let stateLock = NSLock()
    private var isActive = false
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    init() {
        activate()
    }

    func invalidate() {
        stateLock.lock()
        guard isActive else {
            stateLock.unlock()
            return
        }
        isActive = false
        stateLock.unlock()

        runOnMain {
            BackgroundAudioManager.shared.requestStop()
            BackgroundLocationManager.shared.requestStop()

            if self.backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = .invalid
            }
        }
    }

    private func activate() {
        stateLock.lock()
        guard !isActive else {
            stateLock.unlock()
            return
        }
        isActive = true
        stateLock.unlock()

        runOnMain {
            BackgroundAudioManager.shared.requestStart()
            BackgroundLocationManager.shared.requestStart()
            self.backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "FluxStoreJITSession") { [weak self] in
                LogManager.shared.addWarningLog("JIT session background task expired")
                self?.invalidate()
            }
        }
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }
}
