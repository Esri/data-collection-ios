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

extension FileManager {
    
    // MARK: Components and Extensions
    
    struct OfflineDirectoryComponents {
        
        static let dataCollection = "data_collection"
        static let offlineMap = "offlineMap"
    }
    
    // MARK: Temporary Map Directory
    
    public static var temporaryOfflineMapDirectoryURL: URL {
        let tmpDir = NSTemporaryDirectory()
        return URL(fileURLWithPath: tmpDir)
            .appendingPathComponent(OfflineDirectoryComponents.dataCollection)
            .appendingPathComponent(OfflineDirectoryComponents.offlineMap)
    }
    
    static func prepareTemporaryOfflineMapDirectory() throws {
        
        let url = temporaryOfflineMapDirectoryURL
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: URLs
    
    private static var baseDocumentsDirectoryURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private static var dataCollectionDocsDirectoryURL: URL {
        return baseDocumentsDirectoryURL.appendingPathComponent(OfflineDirectoryComponents.dataCollection)
    }
    
    public static var offlineMapDirectoryURL: URL {
        return dataCollectionDocsDirectoryURL.appendingPathComponent(OfflineDirectoryComponents.offlineMap)
    }
    
    // MARK: Offline Directory
    
    static func buildOfflineMapDirectory() {
        
        let path = offlineMapDirectoryURL
        
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("[Error: AppFiles] could not create directory: \(path) with error:", error.localizedDescription)
        }
    }
}
