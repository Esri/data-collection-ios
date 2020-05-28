//// Copyright 2018 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import ArcGIS

/// The app's work mode can be `online` or `offline` .
/// `WorkMode` is an enum `Int` (raw representable) for easy storage in `UserDefaults`.
/// - Note: Cases start at 1 because `UserDefaults` returns `0` if no value is set for integer key.
enum WorkMode: Int {
    
    case online = 1
    case offline
    
    private static let userDefaultsKey = "WorkMode.\(String.webMapItemID)"
    
    func storeDefaultWorkMode() {
        UserDefaults.standard.set(self.rawValue, forKey: WorkMode.userDefaultsKey)
    }
    
    static func retrieveDefaultWorkMode() -> WorkMode {
        
        let storedRaw = UserDefaults.standard.integer(forKey: WorkMode.userDefaultsKey)
        return WorkMode(rawValue: storedRaw) ?? WorkMode.online
    }
}

// MARK: Offline Map

extension AppContext {
    
    /// Load the offline map if it exists and set the `currentMap` according to the app's work mode.
    ///
    /// This is called on application launch.
    /// - Note: It is possible for the app to retrieve, load and maintain a reference to an offline map even if the stored `WorkMode` is `online`.
    /// This is so that the user can switch between online and offline maps easily.
    func loadOfflineMobileMapPackageAndSetMapForCurrentWorkMode() {
        
        loadOfflineMobileMapPackage { [weak self] (map) in
            
            guard let offlineMap = map, appContext.workMode == .offline else {
                appContext.setWorkModeOnlineWithMapFromPortal()
                return
            }
            
            self?.set(offlineMap: offlineMap)
        }
    }
    
    /// Load the offline map (if it has been downloaded) and set it to `currentMap`.
    func loadOfflineMobileMapPackageAndSetMap() {
        
        loadOfflineMobileMapPackage { [weak self] (map) in
            
            guard let offlineMap = map else {
                appContext.setWorkModeOnlineWithMapFromPortal()
                return
            }
            
            self?.set(offlineMap: offlineMap)
        }
    }
    
    /// Load the downloaded `AGSMobileMapPackage` if possible, setting the kv-observable `hasOfflineMap` boolean property and returning an AGSMap.
    private func loadOfflineMobileMapPackage(_ completion: @escaping (AGSMap?) -> Void) {
        
        self.mobileMapPackage = LastSyncMobileMapPackage(
            fileURL: .offlineMapDirectoryURL(forWebMapItemID: .webMapItemID),
            userDefaultsKey: String(format: "LastSyncMobileMapPackage.%@", String.webMapItemID)
        )
        
        guard let mmpk = self.mobileMapPackage else {
            hasOfflineMap = false
            completion(nil)
            return
        }
        
        mmpk.load(completion: { [weak self] (error) in
            
            if let error = error {
                print("[Error: Mobile Map Package]", error.localizedDescription)
            }
            
            let offlineMap = self?.getOfflineMapAndUpdateAppContext()
            
            completion(offlineMap)
        })
    }
    
    fileprivate func getOfflineMapAndUpdateAppContext() -> AGSMap? {
        
        hasOfflineMap = offlineMap != nil
        
        if !hasOfflineMap { mobileMapPackage = nil }
        
        return offlineMap
    }

    
    /// Swap from the online map to the offline map.
    ///
    /// The offline map is opened from the downloaded `AGSMobileMapPackage`.
    /// - Note: This requires and assumes that `loadOfflineMobileMapPackageAndSetBestMap()` or `loadDownloaded(::)` has been previously called.
    func setMapFromOfflineMobileMapPackage() -> Bool {
        
        guard let currentOfflineMap = offlineMap else {
            return false
        }
        
        set(offlineMap: currentOfflineMap)
        
        return true
    }
    
    fileprivate func set(offlineMap map: AGSMap) {
        
        currentMap = map
        workMode = .offline
    }
    
    @discardableResult
    func moveDownloadedMapToOfflineMapDirectory() throws -> URL?  {
        return try FileManager.default.replaceItemAt(
            .offlineMapDirectoryURL(forWebMapItemID: .webMapItemID),
            withItemAt: .temporaryOfflineMapDirectoryURL(forWebMapItemID: .webMapItemID)
        )
    }
    

    /// Clean up and remove any downloaded `AGSMobileMapPackage`, and prepare the local storage directory for the next offline map.
    func deleteOfflineMap() throws {
        
        mobileMapPackage?.clearLastSyncDate()
        mobileMapPackage = nil
        hasOfflineMap = false

        try appFiles.deleteContentsOfOfflineMapDirectory()
        try appFiles.prepareOfflineMapDirectory()
    }
    
    /// Delete any offline map then attempt to set the current map to the online web map, and the work mode to online.
    func deleteOfflineMapAndAttemptToGoOnline() throws {
        try deleteOfflineMap()
        
        if appReachability.isReachable {
            setWorkModeOnlineWithMapFromPortal()
        }
        else {
            currentMap = nil
        }
    }
}

// MARK: Online Map
extension AppContext {
    
    /// Open a web map stored in the portal. Set it to the current map and the work mode to online.
    func setWorkModeOnlineWithMapFromPortal() {
        let portalItem = AGSPortalItem(
            portal: portal,
            itemID: .webMapItemID
        )
        let map = AGSMap(item: portalItem)
        set(onlineMap: map)
    }
    
    fileprivate func set(onlineMap map: AGSMap) {
        
        currentMap = map
        workMode = .online
    }
}
