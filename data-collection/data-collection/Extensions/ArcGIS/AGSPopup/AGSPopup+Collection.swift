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

extension Collection where Iterator.Element == AGSPopup {
    
    /// Return the collection's `AGSPopup` representing the feature nearest to a given map point.
    ///
    /// - Parameter mapPoint: The point with which to compare geometries.
    ///
    /// - Returns: The collection's pop-up for the feature nearest to the mapPoint parameter.
    
    func popupNearestTo(mapPoint: AGSPoint) -> AGSPopup? {
        
        guard !isEmpty else { return nil }
        
        var nearestPopup: (popup: AGSPopup, delta: Double)?
        
        for popup in self {
            
            guard let popupPoint = popup.geoElement.geometry else { continue }
            
            // We can use the `AGSGeometryEngine` to calculate the distance (`Double`) between two geometries.
            let delta = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: popupPoint)
            
            guard let nearest = nearestPopup else {
                nearestPopup = (popup, delta)
                continue
            }
            
            // Update nearestPopup if this popup is closer.
            if delta < nearest.delta {
                nearestPopup = (popup, delta)
            }
        }
        
        return nearestPopup?.popup
    }
}
