//
//  Bundle+AltStore.swift
//  AltStore
//
//  Created by Riley Testut on 5/30/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation

public extension Bundle
{
    struct Info
    {
        public static let deviceID = "ALTDeviceID"
        public static let serverID = "ALTServerID"
        public static let certificateID = "ALTCertificateID"
        public static let appGroups = "ALTAppGroups"
        public static let altBundleID = "ALTBundleIdentifier"

        /// Historical SideStore identifier segment; prefer `Bundle.main.bundleIdentifier` via `appbundleIdentifier`.
        public static let orgbundleIdentifier = "com.flux"
        /// Main app bundle id from the running app (FluxStore uses `com.flux.fluxstore`, not hardcoded SideStore IDs).
        public static var appbundleIdentifier: String {
            Bundle.main.bundleIdentifier ?? "com.flux.fluxstore"
        }
        public static let devicePairingString = "ALTPairingFile"
        public static let urlTypes = "CFBundleURLTypes"
        public static let exportedUTIs = "UTExportedTypeDeclarations"
        public static let backgroundModes = "UIBackgroundModes"
        
        public static let untetherURL = "ALTFugu14UntetherURL"
        public static let untetherRequired = "ALTFugu14UntetherRequired"
        public static let untetherMinimumiOSVersion = "ALTFugu14UntetherMinimumVersion"
        public static let untetherMaximumiOSVersion = "ALTFugu14UntetherMaximumVersion"
    }
}

public extension Bundle
{
    var infoPlistURL: URL {
        let infoPlistURL = self.bundleURL.appendingPathComponent("Info.plist")
        return infoPlistURL
    }
    
    var provisioningProfileURL: URL {
        let provisioningProfileURL = self.bundleURL.appendingPathComponent("embedded.mobileprovision")
        return provisioningProfileURL
    }
    
    var certificateURL: URL {
        let certificateURL = self.bundleURL.appendingPathComponent("ALTCertificate.p12")
        return certificateURL
    }
    
    var altstorePlistURL: URL {
        let altstorePlistURL = self.bundleURL.appendingPathComponent("AltStore.plist")
        return altstorePlistURL
    }
}

public extension Bundle
{
    /// App group prefix must match `group.<GROUP_ID>` in Info.plist (same as bundle id for FluxStore).
    static var baseAltStoreAppGroupID: String {
        "group." + Bundle.Info.appbundleIdentifier
    }

    var appGroups: [String] {
        return self.infoDictionary?[Bundle.Info.appGroups] as? [String] ?? []
    }
    
    var altstoreAppGroup: String? {
        guard let appGroup = self.appGroups.first(where: { $0.contains(Bundle.baseAltStoreAppGroupID) }) else {
            return nil
        }

        // If the group cannot be opened on-device, treat it as unavailable so startup can fall back safely.
        guard UserDefaults(suiteName: appGroup) != nil else {
            return nil
        }

        return appGroup
    }

    /// User-visible app name from Info.plist (matches home screen label).
    public var altAppDisplayName: String {
        if let n = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !n.isEmpty { return n }
        if let n = object(forInfoDictionaryKey: "CFBundleName") as? String, !n.isEmpty { return n }
        return "FluxStore"
    }
    
    var completeInfoDictionary: [String : Any]? {
        let infoPlistURL = self.infoPlistURL
        return NSDictionary(contentsOf: infoPlistURL) as? [String : Any]
    }
}
