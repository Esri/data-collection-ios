//// Copyright 2017 Esri
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

// MARK: Protocol Declarations

protocol AppUserDefaultsProtocol {
    static var userDefaultsKey: String { get }
    associatedtype ValueType
}

// MARK: Protocol Extensions

extension AppUserDefaultsProtocol {
    
    static func setUserDefault(_ value: ValueType?) {
        UserDefaults.standard.set(value, forKey: userDefaultsKey)
    }
    
    static func clearUserDefaultValue() {
        UserDefaults.standard.set(nil, forKey: userDefaultsKey)
    }
    
    static func getUserDefaultValue() -> ValueType? {
        return UserDefaults.standard.value(forKey: userDefaultsKey) as? ValueType
    }
}

