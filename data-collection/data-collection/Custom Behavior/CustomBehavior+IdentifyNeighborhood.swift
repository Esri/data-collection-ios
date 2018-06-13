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

// TODO finish
func enrich(popup: AGSPopup, withNeighborhoodIdentifyForPoint point: AGSPoint, completion: @escaping () -> Void) {
    
    guard let map = appContext.currentMap else {
        completion()
        return
    }
    
    var foundNeighborhoodTable: AGSArcGISFeatureTable?
    
    for layer in map.operationalLayers {
        if let featureLayer = layer as? AGSFeatureLayer, let featureTable = featureLayer.featureTable as? AGSArcGISFeatureTable {
            if featureTable.tableName == "Neighborhoods" {
                foundNeighborhoodTable = featureTable
                break
            }
        }
    }
    
    guard let neighborhoodFeatureTable = foundNeighborhoodTable else {
        completion()
        return
    }
    
    let query = AGSQueryParameters()
    query.geometry = point
//    query.maxFeatures = 1
    query.spatialRelationship = .within
    
    neighborhoodFeatureTable.queryFeatures(with: query, completion: { (result, error) in
        
        guard error == nil else {
            print("[Error: Neighborhood Feature Table] can't query for feature:", error!.localizedDescription)
            completion()
            return
        }
        
        guard let features = result, let feature = features.featureEnumerator().allObjects.first as? AGSArcGISFeature else {
            print("[Neighborhood Feature Table] point outside neighborhood boundaries.")
            completion()
            return
        }
        
        let neighbohoodKey = "NAME"
        let treeKey = "Neighborhood"
        
        if
            let neighbhorhoodKeys = feature.attributes.allKeys as? [String],
            neighbhorhoodKeys.contains(neighbohoodKey),
            let treeLayerKeys = popup.geoElement.attributes.allKeys as? [String],
            treeLayerKeys.contains(treeKey) {
            
            popup.geoElement.attributes[treeKey] = feature.attributes[neighbohoodKey]
        }
        
        completion()
    })
}
