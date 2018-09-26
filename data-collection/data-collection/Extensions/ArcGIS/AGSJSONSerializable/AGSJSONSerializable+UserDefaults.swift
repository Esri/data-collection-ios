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

extension AGSJSONSerializable {
    
    /// Retrieve a JSON object from `UserDefaults` and instantiate an appropriate ArcGIS Runtime object if possible.
    ///
    /// Serializing `AGSJSONSerializable` objects to JSON allows them to be stored in `UserDefaults`.
    ///
    /// - Parameters:
    ///     - withKey: `UserDefaults` key.
    ///
    /// - SeeAlso: `UserDefaults+AGSJSONSerializable` `func set(_ jsonSerializable: AGSJSONSerializable?, forKey key: String)`
    
    static func retrieveFromUserDefaults(forKey key: String) -> Self? {
        do {
            guard let json = UserDefaults.standard.value(forKey: key) else { return nil }
            return try Self.fromJSON(json) as? Self
        }
        catch {
            print("[Error: AGSJSONSerializable] could not serialize object from JSON.", error.localizedDescription)
        }
        return nil
    }
}
