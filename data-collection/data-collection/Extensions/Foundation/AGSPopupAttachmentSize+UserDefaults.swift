//// Copyright 2019 Esri
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

extension String {
    static let defaultAttachmentSize = "AGSPopupAttachmentSize.PreferredAttachmentSize.UserDefaultKey"
}

extension UserDefaults {
    
    func setRawRepresentable<RR: RawRepresentable>(_ value: RR, for key: String) {
        set(value.rawValue, forKey: key)
    }
    
    func getRawRepresentable<RR: RawRepresentable>(forKey key: String) -> RR? {
        if let value = value(forKey: key) as? RR.RawValue {
            return RR(rawValue: value)
        }
        else {
            return nil
        }
    }
}