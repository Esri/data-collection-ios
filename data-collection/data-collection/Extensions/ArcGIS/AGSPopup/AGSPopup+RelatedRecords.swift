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

    /// Facilitates finding a one-to-many `AGSRelationshipInfo` associated between one pop-up and another.
    ///
    /// - Parameter popup: The pop-up with which to investigate for a relationship.
    ///
    /// - Returns: An `AGSRelationshipInfo`, if one exists between the two pop-ups.
    
    func oneToManyRelationship(withPopup popup: AGSPopup) -> AGSRelationshipInfo? {
        
        guard
            let feature = geoElement as? AGSArcGISFeature,
            let relationships = feature.oneToManyRelationshipInfos,
            let relatedFeature = popup.geoElement as? AGSArcGISFeature,
            let relatedFeatureTable = relatedFeature.featureTable as? AGSArcGISFeatureTable
            else {
                return nil
        }
        
        return relationships.first { (info) -> Bool in return info.relatedTableID == relatedFeatureTable.serviceLayerID }
    }
}
