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

func enrich(popup: AGSPopup, withNeighborhoodIdentifyForPoint point: AGSPoint, completion: @escaping () -> Void) {
    
    guard let map = appContext.currentMap else {
        print("[Error: Identify Neighborhood] no current map.")
        completion()
        return
    }
    
    let foundNeighborhoodLayer = map.operationalLayers.first { (layer) -> Bool in
        
        guard let featureLayer = layer as? AGSFeatureLayer, let featureTable = featureLayer.featureTable as? AGSArcGISFeatureTable else {
            return false
        }
        
        return featureTable.tableName == "Neighborhoods"
        
    }
    
    guard let neighborhoodFeatureTable = (foundNeighborhoodLayer as? AGSFeatureLayer)?.featureTable as? AGSArcGISFeatureTable else {
        print("[Error: Identify Neighborhood] could not find neighborhood table.")
        completion()
        return
    }
    
    let query = AGSQueryParameters()
    query.geometry = point
    query.spatialRelationship = .within
    
    neighborhoodFeatureTable.queryFeatures(with: query) { (result, error) in
        
        guard error == nil else {
            print("[Error: Neighborhood Feature Table] can't query for feature:", error!.localizedDescription)
            completion()
            return
        }
        
        guard let features = result, let feature = features.featureEnumerator().nextObject() as? AGSArcGISFeature else {
            print("[Neighborhood Feature Table] point outside neighborhood boundaries.")
            completion()
            return
        }
        
        let neighbohoodKey = "NAME"
        let treeKey = "Neighborhood"
        
        if feature.attributes[neighbohoodKey] != nil && popup.geoElement.attributes[treeKey] != nil {
            popup.geoElement.attributes[treeKey] = feature.attributes[neighbohoodKey]
        }
        else {
            print("[Error: Identify Neighborhood] could not find neighborhood key in attributes.")
        }
        
        completion()
    }
}
