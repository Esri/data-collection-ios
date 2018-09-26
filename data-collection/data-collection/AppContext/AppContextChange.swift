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

enum AppContextChange {
    
    struct Key: RawRepresentable, Hashable {
        
        typealias RawValue = String
        
        var rawValue: RawValue
        
        init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        // Needed to satisfy the protocol requirement.
        init?(rawValue: RawValue) {
            self.init(rawValue)
        }
        
        static let currentPortal = Key("AppContextChange.currentPortal")
        static let currentMap = Key("AppContextChange.currentMap")
        static let hasOfflineMap = Key("AppContextChange.hasOfflineMap")
        static let locationAuthorization = Key("AppContextChange.locationAuthorization")
        static let reachability = Key("AppContextChange.reachability")
        static let workMode = Key("AppContextChange.workMode")
        static let lastSync = Key("AppContextChange.lastSync")
    }
    
    case currentPortal((AGSPortal) -> Void)
    case currentMap((AGSMap?) -> Void)
    case hasOfflineMap((Bool) -> Void)
    case locationAuthorization((Bool) -> Void)
    case reachability((Bool) -> Void)
    case workMode((WorkMode) -> Void)
    case lastSync((Date?) -> Void)
    
    var notificationClosure: Any {
        switch self {
        case .currentPortal(let closure):
            return closure
        case .currentMap(let closure):
            return closure
        case .hasOfflineMap(let closure):
            return closure
        case .locationAuthorization(let closure):
            return closure
        case .reachability(let closure):
            return closure
        case .workMode(let closure):
            return closure
        case .lastSync(let closure):
            return closure
        }
    }
    
    var key: Key {
        switch self {
        case .currentPortal(_):
            return Key.currentPortal
        case .currentMap(_):
            return Key.currentMap
        case .hasOfflineMap(_):
            return Key.hasOfflineMap
        case .locationAuthorization(_):
            return Key.locationAuthorization
        case .reachability(_):
            return Key.reachability
        case .workMode(_):
            return Key.workMode
        case .lastSync(_):
            return Key.lastSync
        }
    }
}
