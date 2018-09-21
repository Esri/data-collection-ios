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
/// `WorkMode` is an enum `Int` (raw representable) for easy storage into `UserDefaults`.
/// - Note: Cases start at 1 because `UserDefaults` returns `0` if no value is set for integer key.
enum WorkMode: Int {
    
    case online = 1
    case offline
    
    private static let userDefaultsKey = "WorkMode.\(AppConfiguration.webMapItemID)"
    
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
    
    /// Upon launch, we want to load the offline map if it exists and set the `currentMap` according to the app's work mode.
    /// If
    /// - Note: It is possible for the app to retrieve, load and maintain a reference to an offline map even if the user defaults work mode is online.
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
    
    /// After a successful download we want to load the offline map if it exists and set it to `currentMap`.
    func loadOfflineMobileMapPackageAndSetMap() {
        
        loadOfflineMobileMapPackage { [weak self] (map) in
            
            guard let offlineMap = map else {
                appContext.setWorkModeOnlineWithMapFromPortal()
                return
            }
            
            self?.set(offlineMap: offlineMap)
        }
    }
    
    /// This private function handles loading the `AGSMobileMapPackage`, setting the kv-observable `hasOfflineMap` boolean property.
    /// and returning an AGSMap.
    private func loadOfflineMobileMapPackage(_ completion: @escaping (AGSMap?) -> Void) {
        
        self.mobileMapPackage = LastSyncMobileMapPackage(fileURL: .offlineMapDirectoryURL(forWebMapItemID: AppConfiguration.webMapItemID),
                                                         userDefaultsKey: "LastSyncMobileMapPackage.\(AppConfiguration.webMapItemID)")
        
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

    /**
     This function assumes `loadOfflineMobileMapPackageAndSetBestMap()` or `loadDownloaded(::)` has been previously called,
     calling this function at the moment a user wishes to swap maps from the online map to the offline mobile map package.
     */
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

        do {
            return try FileManager.default.replaceItemAt(.offlineMapDirectoryURL(forWebMapItemID: AppConfiguration.webMapItemID), withItemAt: .temporaryOfflineMapDirectoryURL(forWebMapItemID: AppConfiguration.webMapItemID))
        }
        catch {
            throw error
        }
    }
    
    /**
     This function is concerned with deleting the entire contents of a downloaded mobile map package and
     then preparing the directory for the next offline map.
     */
    func deleteOfflineMap() throws {
        
        mobileMapPackage?.clearLastSyncDate()
        mobileMapPackage = nil
        hasOfflineMap = false

        do {
            try appFiles.deleteContentsOfOfflineMapDirectory()
            try appFiles.prepareOfflineMapDirectory()
        }
        catch {
            throw error
        }
    }
    
    /**
     This function deletes an offline map and then attempts to set the current map to the online web map and work mode to online.
     */
    func deleteOfflineMapAndAttemptToGoOnline() throws {
        
        do {
            try deleteOfflineMap()
        }
        catch {
            throw error
        }
        
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
    
    /**
     This function builds a web map stored in the portal and sets it to the current map and the work mode to online.
     */
    func setWorkModeOnlineWithMapFromPortal() {
        
        let portalItem = AGSPortalItem(portal: portal, itemID: AppConfiguration.webMapItemID)
        let map = AGSMap(item: portalItem)
        set(onlineMap: map)
    }
    
    fileprivate func set(onlineMap map: AGSMap) {
        
        currentMap = map
        workMode = .online
    }
}
