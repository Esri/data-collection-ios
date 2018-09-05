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

extension URL {
    
    static func temporaryOfflineMapDirectoryURL(forWebMapItemID itemID: String) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(FileManager.OfflineDirectoryComponents.dataCollection)
            .appendingPathComponent(FileManager.OfflineDirectoryComponents.offlineMap)
            .appendingPathComponent(itemID)
    }
    
    static func offlineMapDirectoryURL(forWebMapItemID itemID: String) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(FileManager.OfflineDirectoryComponents.dataCollection)
            .appendingPathComponent(FileManager.OfflineDirectoryComponents.offlineMap)
            .appendingPathComponent(itemID)
    }
}
