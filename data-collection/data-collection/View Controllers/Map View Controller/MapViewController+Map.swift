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

extension MapViewController {
    
    func updateForMap() {
        
        mapViewMode = appContext.currentMap != nil ? .defaultView : .disabled

        guard let map = mapView.map else {
            delegate?.mapViewController(self, didUpdateTitle: "No Map")
            delegate?.mapViewController(self, shouldAllowNewFeature: false)
            return
        }
        
        map.load { [weak self] (error) in
            
////             TODO REMOVE
//            let ref = AGSSpatialReference.webMercator()
//            let envelope = AGSEnvelope(xMin: -13654697.240103, yMin: 5705739.420356, xMax: -13654697.240103, yMax: 5705739.420356, spatialReference: ref)
//            let viewpoint = AGSViewpoint(targetExtent: envelope)
//            self?.mapView.setViewpoint(viewpoint)
////             \ REMOVE
            
            guard error == nil else {
                print("[Error: Map Load]", error!.localizedDescription)
                return
            }
            
            guard let weakSelf = self else {
                return
            }
            
            // 1 set map title from map definition
            weakSelf.delegate?.mapViewController(weakSelf, didUpdateTitle: map.item?.title ?? "Map")
            
            guard let operationalLayers = map.operationalLayers as? [AGSFeatureLayer] else {
                weakSelf.delegate?.mapViewController(weakSelf, shouldAllowNewFeature: false)
                return
            }
            
            AGSLoadObjects(operationalLayers, { [weak self] (completion) in
                
                guard let weakSelf = self else {
                    return
                }
                
                guard let addableLayers = operationalLayers.featureAddableLayers, addableLayers.count > 0 else {
                    weakSelf.delegate?.mapViewController(weakSelf, shouldAllowNewFeature: false)
                    return
                }
                
                weakSelf.delegate?.mapViewController(weakSelf, shouldAllowNewFeature: true)
            })
        }
    }
    
}
