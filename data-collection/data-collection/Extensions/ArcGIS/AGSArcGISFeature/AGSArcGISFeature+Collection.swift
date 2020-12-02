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

extension Collection where Iterator.Element == AGSArcGISFeature {
    
    /// Build an array of `AGSPopup` objects of same-table feature (`AGSArcGISFeature`) objects.
    ///
    /// - Returns: An array of pop-up objects that can be empty.
    ///
    /// - Throws: An error if the first feature table in the collection is not popup enabled
    /// or if subsequent features are not of the same table as the first.
    
    func asPopups() throws -> [AGSPopup] {
        
        guard count > 0 else {
            return [AGSPopup]()
        }
        
        return try map { (feature: AGSArcGISFeature) -> AGSPopup in
            
            guard let featureTable = feature.featureTable else {
                throw AGSArcGISFeature.MissingTableError(feature: feature)
            }
            
            guard featureTable.isPopupActuallyEnabled else {
                throw AGSFeatureTable.PopupsAreNotEnabledError(table: featureTable)
            }
            
            return AGSPopup(
                geoElement: feature,
                popupDefinition: featureTable.popupDefinition
            )
        }        
    }
}

// MARK:- Errors

extension AGSArcGISFeature {
    struct MissingTableError: LocalizedError {
        let feature: AGSArcGISFeature
        var errorDescription: String? { "Feature is missing it's table." }
    }
}

extension AGSFeatureTable {
    struct PopupsAreNotEnabledError: LocalizedError {
        let table: AGSFeatureTable
        var errorDescription: String? { "Pop-ups are not enabled for feature table." }
    }
}
