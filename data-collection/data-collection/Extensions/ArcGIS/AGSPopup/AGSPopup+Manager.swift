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

extension AGSPopup {
    
    /// Facilitates building a pop-up manager from a pop-up.
    ///
    /// - Returns: The newly created pop-up manager.
    
    func asManager() -> AGSPopupManager {
        return AGSPopupManager(popup: self)
    }
    
    /// Facilitates determining if a pop-up is editable.
    ///
    /// - Note: This property should be used sparingly due to the memory cost incurred by the operation.
    
    var isEditable: Bool {
        return asManager().shouldAllowEdit
    }
}
