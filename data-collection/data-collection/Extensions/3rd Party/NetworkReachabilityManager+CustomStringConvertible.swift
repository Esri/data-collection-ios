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

extension NetworkReachabilityManager.NetworkReachabilityStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .notReachable:
            return "Not reachable"
        case .reachable(let type):
            return "Reachable via \(String(describing: type))"
        case .unknown:
            return "Unknown"
        }
    }
}

extension NetworkReachabilityManager.ConnectionType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .ethernetOrWiFi:
            return "Ethernet or WiFi"
        case .wwan:
            return "WWAN"
        }
    }
}
