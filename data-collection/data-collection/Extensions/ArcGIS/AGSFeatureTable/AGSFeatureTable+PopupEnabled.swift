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

extension AGSFeatureTable {
    
    /// This computed property informs the app if the feature table has popups enabled and that the table contains it's cooresponding pop-up definition.
    ///
    /// - Attention: It is possible for pop-ups to be enabled on a table where that table does not contain a pop-up definition.
    /// This behavior might change in future releases of the ArcGIS Runtime.
    /// If this change is enacted, the continued use of this property shouldn't break the app.
    
    var isPopupActuallyEnabled: Bool {
        return isPopupEnabled && popupDefinition != nil
    }
}
