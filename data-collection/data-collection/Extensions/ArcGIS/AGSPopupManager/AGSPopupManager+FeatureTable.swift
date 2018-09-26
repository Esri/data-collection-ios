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

// Computed variables that allow the pop-up manager to more quickly access it's pop-up's feature's underlying table.
extension AGSPopupManager {
    
    var table: AGSFeatureTable? {
        return (popup.geoElement as? AGSArcGISFeature)?.featureTable
    }
    
    var tableName: String? {
        return table?.tableName
    }
}
