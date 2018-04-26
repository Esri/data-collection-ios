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
    
    func isPopupEnabledFor(relationshipInfo: AGSRelationshipInfo) -> Bool {
        
        let operativeID = relationshipInfo.relatedTableID
        
        for layer in operationalLayers {
            guard let featureLayer = layer as? AGSFeatureLayer, let featureTable = featureLayer.featureTable as? AGSServiceFeatureTable else {
                continue
            }
            if featureTable.serviceLayerID == operativeID {
                return featureTable.isPopupActuallyEnabled
            }
        }
        for table in tables {
            guard let featureTable = table as? AGSServiceFeatureTable else {
                continue
            }
            if featureTable.serviceLayerID == operativeID {
                return featureTable.isPopupActuallyEnabled
            }
        }
        return false
    }
}
