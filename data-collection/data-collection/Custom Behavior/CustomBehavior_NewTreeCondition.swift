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

/// Behavior specific to the _Trees of Portland_ web map.
///
/// When creating a new tree, this function populates the condition attribute with a default value. 
/// The default value is "good".
///
/// - Parameters popup: The new tree.
func configureDefaultCondition(forPopup popup: AGSPopup) {
    
    let conditionKey = "Condition"
    let defaultCondition = "Good"
    
    if popup.geoElement.attributes[conditionKey] != nil {
        popup.geoElement.attributes[conditionKey] = defaultCondition
    }
    else {
        print("[Error: Tree Condition] could not find condition key in attributes.")
    }  
}
