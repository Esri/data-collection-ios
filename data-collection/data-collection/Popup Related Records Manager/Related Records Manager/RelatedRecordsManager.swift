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

/// Represents and manages the related records of a popup and one of it's relationship infos.
///
/// This class is to not to be used directly but instead to be subclassed.
class RelatedRecordsManager {
    
    weak internal private(set) var popup: AGSPopup?
    weak var relationshipInfo: AGSRelationshipInfo?
    weak var relatedTable: AGSArcGISFeatureTable?
    
    init?(relationshipInfo info: AGSRelationshipInfo, table: AGSArcGISFeatureTable?, popup: AGSPopup) {
        
        guard info.cardinality == .oneToMany else {
            return nil
        }
        
        self.relationshipInfo = info
        self.relatedTable = table
        self.popup = popup
    }
    
    /// Load the related record(s) provided a popup, relationship info and related table.
    ///
    /// - Parameter completion: Either an array of related pop-ups or an error, but not both.
    ///
    func load(records completion: @escaping ([AGSPopup]?, Error?) -> Void) {
        
        guard let feature = self.popup?.geoElement as? AGSArcGISFeature else {
            completion(nil, FeatureTableError.missingFeature)
            return
        }
        
        guard let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
            completion(nil, FeatureTableError.missingFeatureTable)
            return
        }
        
        guard let info = self.relationshipInfo else {
            completion(nil, FeatureTableError.missingRelationshipInfos)
            return
        }
        
        featureTable.queryRelatedFeaturesAsPopups(forFeature: feature, relationship: info) { (popupsResults, error) in
            
            guard error == nil else {
                completion(nil, error!)
                return
            }
            
            guard let popups = popupsResults else {
                completion(nil, FeatureTableError.queryResultsMissingPopups)
                return
            }
            
            completion(popups, nil)
        }
    }
    
    var name: String? {
        return relatedTable?.tableName
    }
}
