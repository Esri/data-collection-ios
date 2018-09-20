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

extension UserDefaults {
    
    /// Facilitates serializing and setting an `AGSJSONSerializable` JSON object to `UserDefaults`.
    ///
    /// Serializing `AGSJSONSerializable` objects to JSON allows them to be stored in `UserDefaults`.
    ///
    /// - Parameters:
    ///     - forKey: `UserDefaults` key.
    ///
    /// - SeeAlso: `AGSJSONSerializable+UserDefaults.swift` `static func retrieveFromUserDefaults(forKey key: String) -> Self?`
    
    func set(_ jsonSerializable: AGSJSONSerializable?, forKey key: String) {
        
        guard let jsonValue = jsonSerializable else {
            self.set((nil as Any?), forKey: key)
            return
        }
        
        do {
            let json = try jsonValue.toJSON()
            set(json, forKey: key)
        }
        catch {
            print("[Error: AGSJSONSerializable] could not serialize object to JSON.", error.localizedDescription)
        }
    }    
}
