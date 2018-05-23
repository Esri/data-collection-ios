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
    
    func clearSelection() {
        
        guard
            let feature = geoElement as? AGSArcGISFeature,
            let table = feature.featureTable,
            let layer = table.featureLayer
            else {
                return
        }
        
        layer.clearSelection()
    }
    
    func select() {
        
        guard
            let feature = geoElement as? AGSArcGISFeature,
            let table = feature.featureTable,
            let layer = table.featureLayer
            else {
                return
        }
        
        layer.select(feature)
    }
    
    var asManager: AGSPopupManager {
        return AGSPopupManager(popup: self)
    }
    
    func loadRelatedRecords(_ completion: @escaping ([RelatedRecordsManager]?)->Void) {
        
        // Kick off load of related records
        var preloadedRelatedRecords = [RelatedRecordsManager]()
        guard
            let feature = geoElement as? AGSArcGISFeature,
            let relatedRecordsInfos = feature.relatedRecordsInfos,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable
            else {
                completion(nil)
                return
        }
        
        // TODO work this rule into AppRules
        for info in relatedRecordsInfos {
            if featureTable.isPopupEnabledFor(relationshipInfo: info), let relatedRecord = RelatedRecordsManager(relationshipInfo: info, feature: feature) {
                preloadedRelatedRecords.append(relatedRecord)
            }
        }
        
        AGSLoadObjects(preloadedRelatedRecords) { (_) in
            completion(preloadedRelatedRecords)
            return
        }
    }
}

extension Collection where Iterator.Element == AGSPopup {
    
    /**
     This function is used to find the nearest point in a collection of points to another point.
     
     Querying a feature layer returns a collection of features, the order for which was in the order
     the feature was discovered in traverse by the backing service as opposed to distance from the query's point.
     */
    func popupNearestTo(mapPoint: AGSPoint) -> AGSPopup? {
        guard count > 0 else {
            return nil
        }
        let sorted = self.sorted(by: { (popupA, popupB) -> Bool in
            let deltaA = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: popupA.geoElement.geometry!)
            let deltaB = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: popupB.geoElement.geometry!)
            return deltaA < deltaB
        })
        return sorted.first
    }
}
