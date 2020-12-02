//// Copyright 2017 Esri
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

extension AGSMapView {
    
    /// Convert a `CGRect` to an `AGSPolygon` in relation to the `AGSMapView`'s bounds.
    ///
    /// - Parameter rect: The rect in point space that is to be converted to a spatial rectangular polygon.
    ///
    /// - Returns: The newly created geometry.
    ///
    /// - Throws: An error if the `fromRect` parameter cannot be contained by the map view's bounds.
    
    func convertExtent(fromRect rect: CGRect) throws -> AGSGeometry {
        
        guard bounds.contains(rect) else {
            throw OutsideBounds(provided: rect, mapView: bounds)
        }
        
        let nw = rect.origin
        let ne = CGPoint(x: rect.maxX, y: rect.minY)
        let se = CGPoint(x: rect.maxX, y: rect.maxY)
        let sw = CGPoint(x: rect.minX, y: rect.maxY)

        let agsNW = screen(toLocation: nw)
        let agsNE = screen(toLocation: ne)
        let agsSE = screen(toLocation: se)
        let agsSW = screen(toLocation: sw)

        return AGSPolygon(points: [agsNW, agsNE, agsSE, agsSW])
    }
}

extension AGSMapView {
    struct OutsideBounds: LocalizedError {
        let provided: CGRect
        let mapView: CGRect
        var errorDescription: String? { "The CGRect provided \(provided) is outside the bounds of the map view \(mapView)." }
    }
}
