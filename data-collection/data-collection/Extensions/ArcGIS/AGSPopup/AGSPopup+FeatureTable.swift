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
    
    /// Facilitates determining if a pop-up's feature has persisted to it's table.
    var isFeatureAddedToTable: Bool {
        return (geoElement as? AGSArcGISFeature)?.objectID != nil
    }
    
    /// Facilitates getting the pop-up's feature's containing table name.
    var tableName: String? {
        return (geoElement as? AGSArcGISFeature)?.featureTable?.tableName
    }
}
