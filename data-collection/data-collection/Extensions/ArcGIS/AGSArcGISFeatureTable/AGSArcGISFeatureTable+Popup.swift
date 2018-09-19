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

extension AGSArcGISFeatureTable {
    
    func isPopupEnabledFor(relationshipInfo: AGSRelationshipInfo) -> Bool {
        
        guard let relatedTables = relatedTables() else {
            return false
        }
        
        let operativeID = relationshipInfo.relatedTableID
        
        for table in relatedTables {
            if table.serviceLayerID == operativeID {
                return table.isPopupActuallyEnabled
            }
        }
        
        return false
    }
    
    func createPopup() -> AGSPopup? {
        
        guard canAddFeature, let feature = createFeature() as? AGSArcGISFeature, let popupDefinition = popupDefinition else {
            return nil
        }
        
        return AGSPopup(geoElement: feature, popupDefinition: popupDefinition)
    }
}
