// Copyright 2019 Esri
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

extension UserDefaults {
    
    /// Write a `RawRepresentable` object to `UserDefaults`.
    ///
    /// Extract the object's `RawValue` and store it in `UserDefaults`.
    ///
    /// - Parameters:
    ///     - forKey: `UserDefaults` key.
    ///
    func setRawRepresentable<RR: RawRepresentable>(_ value: RR?, forKey key: String) {
        set(value?.rawValue, forKey: key)
    }
    
    /// Read a `RawRepresentable` object from `UserDefaults`.
    ///
    /// Build a `RawRepresentable` object from its `RawValue` stored in `UserDefaults`.
    ///
    /// - Parameters:
    ///     - forKey: `UserDefaults` key.
    ///
    func rawRepresentable<RR: RawRepresentable>(forKey key: String) -> RR? {
        (value(forKey: key) as? RR.RawValue).flatMap { RR(rawValue: $0) }
    }
}
