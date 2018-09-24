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

/// Represents and manages a many-to-one related records of a popup.
class ManyToOneManager: RelatedRecordsManager {
    
    // Returns first a staged
    var relatedPopup: AGSPopup? {
        get {
            return stagedRelatedPopup ?? currentRelatedPopup
        }
        set {
            stagedRelatedPopup = newValue
        }
    }
    
    private var currentRelatedPopup: AGSPopup?
    
    private var stagedRelatedPopup: AGSPopup?
    
    func load(records completion: @escaping (Error?) -> Void) {
        
        super.load { [weak self] (popupsResults, error) in
            
            if let err = error {
                completion(err)
                return
            }
            
            guard let popups = popupsResults else {
                completion(FeatureTableError.queryResultsMissingPopups)
                return
            }
            
            self?.currentRelatedPopup = popups.first
            
            completion(nil)
        }
    }
    
    func cancelChange() {
        
        stagedRelatedPopup = nil
    }
    
    func commitChange() throws {
        
        guard let info = relationshipInfo else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        guard let newRelatedPopup = stagedRelatedPopup else {
            if info.isComposite {
                throw RelatedRecordsManagerError.invalidPopup
            }
            return
        }
        
        stagedRelatedPopup = nil
        
        guard
            let feature = popup?.geoElement as? AGSArcGISFeature,
            let relatedFeature = newRelatedPopup.geoElement as? AGSArcGISFeature
            else {
                throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        feature.relate(to: relatedFeature, relationshipInfo: info)
        
        currentRelatedPopup = newRelatedPopup
    }
}
