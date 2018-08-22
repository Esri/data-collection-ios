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

class LastSync: AppUserDefaultsProtocol {
    
    internal private(set) var date: Date? {
        didSet {
            LastSync.setUserDefault(date)
            appNotificationCenter.post(name: .lastSyncDidChange, object: nil)
        }
    }
    
    init() {
        self.date = LastSync.getUserDefaultValue()
    }
    
    func setNow() {
        date = Date()
    }
    
    func clear() {
        date = nil
    }
    
    // MARK: User Defaults Protocol
    
    typealias ValueType = Date

    static var defaultsObjectDomain: String {
        return "LastSync"
    }
}
