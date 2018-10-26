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

extension AGSMap {
    
    /// Return **all** offline tables contained in a map, considering both feature layers and feature tables.
    ///
    /// This can be used to compute if there have been changes to the offline map since the date it was last synchronized.
    
    var allOfflineTables: [AGSGeodatabaseFeatureTable] {

        return tables.compactMap { return ($0 as? AGSGeodatabaseFeatureTable) } +
            operationalLayers.compactMap { return (($0 as? AGSFeatureLayer)?.featureTable as? AGSGeodatabaseFeatureTable) }
    }
    
    var allServiceTables: [AGSServiceFeatureTable] {
        
        return tables.compactMap { return ($0 as? AGSServiceFeatureTable) } +
            operationalLayers.compactMap { return (($0 as? AGSFeatureLayer)?.featureTable as? AGSServiceFeatureTable) }
    }
}
