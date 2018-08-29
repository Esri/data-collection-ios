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

enum WorkMode: Int, AppUserDefaultsProtocol {
    
    case online = 0
    case offline = 1
    
    func storeDefaultWorkMode() {
        WorkMode.setUserDefault(self.rawValue)
    }
    
    static var defaultWorkMode: WorkMode {
        
        guard let storedMode = WorkMode.getUserDefaultValue() else { return .online }
        
        return WorkMode(rawValue: storedMode) ?? WorkMode.online
    }
    
    // MARK: User Defaults Protocol
    
    typealias ValueType = Int
    
    static var objectDomain: String { return "WorkMode" }
}

// MARK: Offline Map
extension AppContext {
    
    /**
     Upon launch, we want to load the offline map if it exists and set the `currentMap` according to the app's work mode.
     
     **Note: it is possible for the app to retrieve, load and maintain a reference to an offline map even if the user defaults work mode is online.
     This is so that the user can switch between online and offline maps easily.
     */
    func loadOfflineMobileMapPackageAndSetMapForCurrentWorkMode() {
        
        loadOfflineMobileMapPackage { [weak self] (map) in
            
            guard let offlineMap = map, appContext.workMode == .offline else {
                appContext.setWorkModeOnlineWithMapFromPortal()
                return
            }
            
            self?.set(offlineMap: offlineMap)
        }
    }
    
    /**
     After a successful download we want to load the offline map if it exists and set it to `currentMap`.
     */
    func loadOfflineMobileMapPackageAndSetMap() {
        
        loadOfflineMobileMapPackage { [weak self] (map) in
            
            guard let offlineMap = map else {
                appContext.setWorkModeOnlineWithMapFromPortal()
                return
            }
            
            self?.set(offlineMap: offlineMap)
        }
    }
    
    /**
     This private function handles loading the `AGSMobileMapPackage`, setting the kv-observable `hasOfflineMap` boolean property
     and returning an AGSMap.
     */
    private func loadOfflineMobileMapPackage(_ completion: @escaping (AGSMap?) -> Void) {
        
        self.mobileMapPackage = AppMobileMapPackage(fileURL: .offlineMapDirectoryURL)
        
        guard let mmpk = self.mobileMapPackage else {
            hasOfflineMap = false
            completion(nil)
            return
        }
        
        mmpk.load(completion: { [weak self] (error) in
            
            if let error = error {
                print("[Error: Mobile Map Package]", error.localizedDescription)
            }
            
            let offlineMap = self?.checkIfHasOfflineMap()
            
            completion(offlineMap)
        })
    }
    
    fileprivate func checkIfHasOfflineMap() -> AGSMap? {
        
        hasOfflineMap = offlineMap != nil
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
            return try FileManager.default.replaceItemAt(.offlineMapDirectoryURL, withItemAt: .temporaryOfflineMapDirectoryURL)
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
            try FileManager.default.removeItem(at: .offlineMapDirectoryURL)
        }
        catch {
            throw error
        }
                
        FileManager.buildOfflineMapDirectory()
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
