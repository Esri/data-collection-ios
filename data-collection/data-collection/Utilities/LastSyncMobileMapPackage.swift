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

class LastSyncMobileMapPackage: AGSMobileMapPackage {
    
    private let userDefaultsKey: String
    
    internal private(set) var lastSyncDate: Date? {
        didSet {
            UserDefaults.standard.set(lastSyncDate, forKey: userDefaultsKey)
            appNotificationCenter.post(name: .lastSyncDidChange, object: nil)
        }
    }
    
    init(fileURL: URL, userDefaultsKey key: String) {
        self.userDefaultsKey = key
        self.lastSyncDate = UserDefaults.standard.value(forKey: key) as? Date
        super.init(fileURL: fileURL)
    }
    
    func setLastSyncNow() {
        lastSyncDate = Date()
    }
    
    func clearLastSyncDate() {
        lastSyncDate = nil
    }
    
    var hasLocalEdits: Bool {
        
        guard let lastSync = lastSyncDate, let map = maps.first else { return false }
        
        return map.allOfflineTables.contains { $0.hasLocalEdits(since: lastSync) }
    }
}

