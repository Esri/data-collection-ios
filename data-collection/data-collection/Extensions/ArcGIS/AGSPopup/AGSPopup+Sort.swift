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

extension Array where Element == AGSPopup {
    
    /// Sorts pop-ups in-place in ascending or descending order.
    ///
    /// - Throws: If the array of popups first field values aren't all of the same type.
    
    mutating func sortPopupsByFirstField(_ order: AGSSortOrder = .ascending) throws {
        
        switch order {
        case .ascending:
            try sort { (left, right) -> Bool in
                return try autoreleasepool { () throws -> Bool in
                    return try left < right
                }
            }
        case .descending:
            try sort { (left, right) -> Bool in
                return try autoreleasepool { () throws -> Bool in
                    return try left > right
                }
            }
        @unknown default:
            fatalError("Unsupported case \(self).")
        }
    }
}
