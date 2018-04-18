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

extension AGSArcGISFeature {
    
    var asPopup: AGSPopup? {
        guard let popupDefinition = featureTable?.popupDefinition else {
            return nil
        }
        return AGSPopup(geoElement: self, popupDefinition: popupDefinition)
    }
    
    var asPopupManager: AGSPopupManager? {
        guard let popup = asPopup else {
            return nil
        }
        return AGSPopupManager(popup: popup)
    }
    
    var popupDefinition: AGSPopupDefinition? {
        return featureTable?.popupDefinition
    }
}

extension Collection where Iterator.Element == AGSArcGISFeature {

    /**
     This function is used to find the nearest point in a collection of points to another point.
     
     Querying a feature layer returns a collection of features, the order for which was in the order
     the feature was discovered in traverse by the backing service as opposed to distance from the query's point.
     */
//    func featureNearestTo(mapPoint: AGSPoint) -> AGSArcGISFeature? {
//        guard count > 0 else {
//            return nil
//        }
//        let sorted = self.sorted(by: { (featureA, featureB) -> Bool in
//            let deltaA = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: featureA.geometry!)
//            let deltaB = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: featureB.geometry!)
//            return deltaA < deltaB
//        })
//        return sorted.first
//    }
}
