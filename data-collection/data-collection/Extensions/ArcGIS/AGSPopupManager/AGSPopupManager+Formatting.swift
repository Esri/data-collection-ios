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

extension AGSPopupManager {
    
    /// Assists in providing the next subsequent popup value provided an `inout` index.
    ///
    /// This is helpful in allowing the popup manager to maintain the index for it's next requested value.
    
    public func nextDisplayFieldStringValue(fieldIndex: inout Int) -> String? {
        
        guard fieldIndex < displayFields.count else {
            return nil
        }
        
        let field = displayFields[fieldIndex]
        let value = formattedValue(for: field)
        
        fieldIndex += 1
        return value
    }
}
