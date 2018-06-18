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

extension AGSRelatedFeatureQueryResult {
    
    var features: [AGSArcGISFeature]? {
        
        return featureEnumerator().allObjects as? [AGSArcGISFeature]
    }
    
    var featuresWithPopupDefinitions: [AGSArcGISFeature]? {
        
        guard let features = features else {
            return nil
        }
        
        return features.filter({ (feature) -> Bool in
            
            guard let featureTable = feature.featureTable else {
                return false
            }
            
            return featureTable.popupDefinition != nil
        })
    }
    
    var featuresAsPopupManagers: [AGSPopupManager]? {
        
        guard let features = featuresWithPopupDefinitions else {
            return nil
        }
        
        return features.compactMap { $0.asPopupManager }
    }
    
    var firstFeature: AGSArcGISFeature? {
        
        return features?.first
    }
    
    var firstFeatureAsPopupManager: AGSPopupManager? {
        
        guard let firstFeature = firstFeature else {
            return nil
        }
        
        return firstFeature.asPopupManager
    }
}
