// Copyright 2020 Esri
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

import ArcGIS

protocol OfflineMapManagerDelegate: class {
    func offlineMapManager(_ manager: OfflineMapManager, didUpdateLastSync date: Date?)
    func offlineMapManager(_ manager: OfflineMapManager, didUpdate status: OfflineMapManager.Status)
    func offlineMapManager(_ manager: OfflineMapManager, didFinishJob result: Result<JobResult, Error>)
}

/// The `OfflineMapManager` is responsible for managing the offline map and offline map jobs.
///
/// The `OfflineMapManager` is designed using the state-machine design pattern, performs a series of tasks,
/// and reports it's status using a delegate pattern to the `AppContext`. The `OfflineMapManager` will:
///
/// - Load offline map.
/// - Delete offline map.
/// - Download map offline using on-demand workflow.
/// - Perform bi-direction sync of offline and online maps.
///
class OfflineMapManager {
    
    private let webMapItemID: String
    
    init(webmap id: String) {
        webMapItemID = id
    }
    
    // MARK: Status
    
    enum Status {
        case none
        case loading(AGSMobileMapPackage)
        case loaded(AGSMobileMapPackage, AGSMap)
        case failed(Error)
    }
    
    private(set) var status: Status = .none {
        didSet {
            
            switch status {
            case .none:
                print(
                    "[Offline Map Manager]",
                    "\n\tNo offline map"
                )
            case .loading(let mmpk):
                print(
                    "[Offline Map Manager]",
                    "\n\tLoading MMPK -", mmpk.fileURL.absoluteString
                )
            case .loaded(let mmpk, let map):
                print(
                    "[Offline Map Manager]",
                    "\n\tLoaded MMPK -", mmpk.fileURL.absoluteString,
                    "\n\tLoaded Map -", map.item?.title ?? "(missing title)"
                )
            case .failed(let error):
                print(
                    "[Offline Map Manager]",
                    "\n\tFailed -", error.localizedDescription
                )
            }
            
            delegate?.offlineMapManager(self, didUpdate: status)
        }
    }
    
    // MARK: Map
    
    var map: AGSMap? {
        if case let .loaded(_, map) = status {
            return map
        }
        else {
            return nil
        }
    }
    
    var hasMap: Bool {
        map != nil
    }
    
    var mapHasLocalEdits: Bool {
        guard let lastSync = lastSync, let map = map else { return false }
        return map.allOfflineTables.contains { $0.hasLocalEdits(since: lastSync) }
    }
    
    // MARK: Load Offline Map
    
    func loadOfflineMobileMapPackage() {
        
        if case .loading = status { return }
        
        // Ensure the offline map directory does exist.
        guard FileManager.default.doesOfflineMapDirectoryExist(id: webMapItemID) else {
            status = .none
            return
        }
        
        // Build offline map mmpk, load.
        let mmpk = AGSMobileMapPackage(
            fileURL: .offlineMapDirectoryURL(forWebMapItemID: PortalConfig.webMapItemID)
        )
        status = .loading(mmpk)
        
        mmpk.load  { [weak self] (error) in
            guard let self = self else { return }
            
            if let error = error {
                self.status = .failed(error)
            }
            else {
                if let map = mmpk.maps.first {
                    self.status = .loaded(mmpk, map)
                }
                else {
                    self.status = .none
                }
            }
        }
    }
    
    // MARK: Delete Offline Map
    
    func deleteOfflineMap() {
        do {
            try FileManager.default.deleteContentsOfOfflineMapDirectory(id: webMapItemID)
            status = .none
        }
        catch {
            status = .failed(error)
        }
        
        clearLastSyncDate()
    }
    
    // MARK: Offline Map Job Manager
    
    struct MissingOfflineMapError: LocalizedError {
        var errorDescription: String? { "Map is not downloaded." }
    }
    
    struct ExistingOfflineMapError: LocalizedError {
        var errorDescription: String? { "A map is already downloaded." }
    }
    
    private lazy var jobManager: OfflineMapJobManager = {
        let manager = OfflineMapJobManager()
        manager.delegate = self
        return manager
    }()
    
    func startJob(job: OfflineMapJobManager.Job) throws {
        
        switch job.type {
        case .GenerateOfflineMap:
            if !canOnDemandDownloadMap {
                throw ExistingOfflineMapError()
            }
        case .OfflineMapSync:
            if !canSyncMap {
                throw MissingOfflineMapError()
            }
        }
        
        return try jobManager.startJob(job)
    }
    
    // MARK: Offline Map Job Manager - On Demand Download Map
    
    private var canOnDemandDownloadMap: Bool {
        switch status {
        case .none, .failed:
            return true
        default:
            return false
        }
    }
    
    func stageOnDemandDownloadMapJob(_ map: AGSMap, extent: AGSGeometry, scale: Double) throws -> OfflineMapJobManager.Job {
        
        if !canOnDemandDownloadMap {
            throw ExistingOfflineMapError()
        }

        try FileManager.default.prepareTemporaryOfflineMapDirectory(id: webMapItemID)
        
        return try jobManager.stageOnDemandDownloadMapJob(
            map,
            extent: extent,
            scale: scale,
            url: .temporaryOfflineMapDirectoryURL(forWebMapItemID: webMapItemID)
        )
    }
    
    // MARK: Offline Map Job Manager - Sync Offline Map
    
    private var canSyncMap: Bool {
        switch status {
        case .loaded:
            return true
        default:
            return false
        }
    }
    
    func stageSyncMapJob() throws -> OfflineMapJobManager.Job {
        
        guard case let .loaded(_, map) = status else {
            throw MissingOfflineMapError()
        }
        
        return try jobManager.stageSyncMapJob(map)
    }
    
    // MARK: Last Sync
    
    internal private(set) var lastSync = UserDefaults.standard.value(forKey: .lastSyncUserDefaultsKey) as? Date {
        didSet {
            UserDefaults.standard.set(lastSync, forKey: .lastSyncUserDefaultsKey)
            delegate?.offlineMapManager(self, didUpdateLastSync: lastSync)
        }
    }
    
    /// - Note: Should be called when a map has downloaded or synchronized successfully.
    func setLastSyncNow() {
        lastSync = Date()
    }
    
    /// - Note: Should be called when a map is deleted.
    func clearLastSyncDate() {
        lastSync = nil
    }
    
    // MARK: Delegate
    
    weak var delegate: OfflineMapManagerDelegate?
}

extension OfflineMapManager: OfflineMapJobManagerDelegate {
    
    func offlineMapJobManager(_ manager: OfflineMapJobManager, job: OfflineMapJobManager.Job, onDemandDownloadResult: AGSGenerateOfflineMapResult) {
        do {
            try FileManager.default.prepareOfflineMapDirectory(id: webMapItemID)
            try FileManager.default.moveOfflineMapFromTemporaryToPermanentDirectory(id: self.webMapItemID)
            status = .loaded(onDemandDownloadResult.mobileMapPackage, onDemandDownloadResult.offlineMap)
            setLastSyncNow()
        }
        catch {
            status = .failed(error)
            clearLastSyncDate()
        }
        delegate?.offlineMapManager(self, didFinishJob: .success(onDemandDownloadResult))
        job.completion?(true)
    }
    
    func offlineMapJobManager(_ manager: OfflineMapJobManager, job: OfflineMapJobManager.Job, syncResult: AGSOfflineMapSyncResult) {
        setLastSyncNow()
        delegate?.offlineMapManager(self, didFinishJob: .success(syncResult))
        job.completion?(true)
    }

    func offlineMapJobManager(_ manager: OfflineMapJobManager, job: OfflineMapJobManager.Job, failed error: Error) {
        status = .failed(error)
        clearLastSyncDate()
        delegate?.offlineMapManager(self, didFinishJob: .failure(error))
        job.completion?(false)
    }
}

// MARK:- User Defaults

private extension String {
    static var lastSyncUserDefaultsKey: String {
         String(format: "LastSyncMobileMapPackage.%@", PortalConfig.webMapItemID)
    }
}

// MARK:- File Management

// This class extension is used to creating and removing directories and items needed for the app in the device's file documents directory.
fileprivate extension FileManager {
    
    // MARK: Temporary Offline Directory
    
    func prepareTemporaryOfflineMapDirectory(id: String) throws {
        let url: URL = .temporaryOfflineMapDirectoryURL(forWebMapItemID: id)
        try createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        try removeItem(at: url)
    }
    
    // MARK: Permanent Offline Directory
    
    func prepareOfflineMapDirectory(id: String) throws {
        let url: URL = .offlineMapDirectoryURL(forWebMapItemID: id)
        try createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    func deleteContentsOfOfflineMapDirectory(id: String) throws {
        let url: URL = .offlineMapDirectoryURL(forWebMapItemID: id)
        try removeItem(at: url)
    }
    
    // MARK: Move From Temporary To Permanent
    
    func moveOfflineMapFromTemporaryToPermanentDirectory(id: String) throws {
        _ = try replaceItemAt(
            .offlineMapDirectoryURL(forWebMapItemID: id),
            withItemAt: .temporaryOfflineMapDirectoryURL(forWebMapItemID: id)
        )
    }
    
    // MARK: Checking If Offline Map Exists
    
    func doesOfflineMapDirectoryExist(id: String) -> Bool {
        
        var isDirectory: ObjCBool = false
        let url = URL.offlineMapDirectoryURL(forWebMapItemID: id)
        
        guard fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue else {
            return false
        }
        
        do {
            let urls = try contentsOfDirectory(atPath: url.path)
            // An offline map exists if the offline map directory has files.
            return !urls.isEmpty
        }
        catch {
            return false
        }
    }
}


// MARK:- File Manager Paths

private extension String {
    static let dataCollection = "data_collection"
    static let offlineMap = "offlineMap"
}

fileprivate extension URL {
    
    /// Build an app-specific URL to a temporary directory used to store the offline map during download.
    ///
    /// - Parameter itemID: The portal itemID that corresponds to your web map.
    ///
    /// - Returns: App-specific URL.
    static func temporaryOfflineMapDirectoryURL(forWebMapItemID itemID: String) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(.dataCollection)
            .appendingPathComponent(.offlineMap)
            .appendingPathComponent(itemID)
    }
    
    /// Build an app-specific URL to where the offline map is stored in the documents directory once downloaded.
    ///
    /// - Parameter itemID: The portal itemID that corresponds to your web map.
    ///
    /// - Returns: App-specific URL.
    static func offlineMapDirectoryURL(forWebMapItemID itemID: String) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(.dataCollection)
            .appendingPathComponent(.offlineMap)
            .appendingPathComponent(itemID)
    }
}

protocol JobResult {}
extension AGSGenerateOfflineMapResult: JobResult {}
extension AGSOfflineMapSyncResult: JobResult {}

private extension AGSMap {
    
    /// Return **all** offline tables contained in a map, considering both feature layers and feature tables.
    ///
    /// This can be used to compute if there have been changes to the offline map since the date it was last synchronized.
    
    var allOfflineTables: [AGSGeodatabaseFeatureTable] {

        return tables.compactMap { return ($0 as? AGSGeodatabaseFeatureTable) } +
            operationalLayers.compactMap { return (($0 as? AGSFeatureLayer)?.featureTable as? AGSGeodatabaseFeatureTable) }
    }
}
