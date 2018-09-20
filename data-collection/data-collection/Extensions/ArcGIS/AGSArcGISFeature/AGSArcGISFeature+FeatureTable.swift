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

extension AGSArcGISFeature {
    
    /// Facilitates getting and setting a feature's (AGSArcGISFeature) object ID.
    ///
    /// - Note: The object ID is indicative of the following:
    /// * If nil, the feature is **not** a member of it's table.
    /// * If negative, the feature is a member only of it's local geodatabase table.
    /// * If positive, the feature is a member of it's service feature table as well as it's local table.
    /// Remember to call `refreshObjectID()` on a feature to ensure it's `objectID` matches the object ID of the cooresponding remote record.
    
    var objectID: Int64? {
        get {
            guard let featureTable = featureTable as? AGSArcGISFeatureTable else {
                return nil
            }
            return attributes[featureTable.objectIDField] as? Int64
        }
        set {
            guard let featureTable = featureTable as? AGSArcGISFeatureTable else {
                return
            }
            attributes[featureTable.objectIDField] = newValue
        }
    }
}
