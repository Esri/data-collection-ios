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

/// This class is used for creating and removing directories and items needed for the app in the device's file documents directory.
class AppFiles {
    
    private var fm: FileManager { return FileManager.default }
    
    struct OfflineDirectoryComponents {
        
        static let dataCollection = "data_collection"
        static let offlineMap = "offlineMap"
    }
    
    /// Builds a temporary directory, if needed, to store a map as it downloads.
    ///
    /// - Throws: FileManager errors thrown as a result of building the temporary offline map directory.
    func prepareTemporaryOfflineMapDirectory() throws {
        
        let url: URL = .temporaryOfflineMapDirectoryURL(forWebMapItemID: AppConfiguration.webMapItemID)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        try fm.removeItem(at: url)
    }
    
    // MARK: Offline Directory    
    func prepareOfflineMapDirectory() throws {
        
        let url: URL = .offlineMapDirectoryURL(forWebMapItemID: AppConfiguration.webMapItemID)
        try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
    
    func deleteContentsOfOfflineMapDirectory() throws {
        
        let url: URL = .offlineMapDirectoryURL(forWebMapItemID: AppConfiguration.webMapItemID)
        try fm.removeItem(at: url)
    }
}

extension URL {
    
    /// Builds an app-specific URL to where the offline map is be stored as it downloads to the temporary directory.
    ///
    /// - Parameter itemID: The portal itemID that corresponds to your web map.
    ///
    /// - Returns: App-specific URL.
    
    static func temporaryOfflineMapDirectoryURL(forWebMapItemID itemID: String) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(AppFiles.OfflineDirectoryComponents.dataCollection)
            .appendingPathComponent(AppFiles.OfflineDirectoryComponents.offlineMap)
            .appendingPathComponent(itemID)
    }
    
    /// Builds an app-specific URL to where the offline map is stored in the documents directory.
    ///
    /// - Parameter itemID: The portal itemID that corresponds to your web map.
    ///
    /// - Returns: App-specific URL.
    
    static func offlineMapDirectoryURL(forWebMapItemID itemID: String) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(AppFiles.OfflineDirectoryComponents.dataCollection)
            .appendingPathComponent(AppFiles.OfflineDirectoryComponents.offlineMap)
            .appendingPathComponent(itemID)
    }
}
