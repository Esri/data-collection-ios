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
    
    func loadMapViewMap() {
        
//        mapViewMode = mapView.map != nil ? .defaultView : .disabled

        guard let map = mapView.map else {
            mapViewMode = .disabled
            delegate?.mapViewController(self, didUpdateTitle: "No Map")
            delegate?.mapViewController(self, shouldAllowNewFeature: false)
            return
        }
        
        let loadCompletion: ((Error?) -> Void)? = { [weak self] (error) in
            
            guard error == nil else {
                print("[Error: Map Load]", error!.localizedDescription)
                self?.mapViewMode = .disabled
                return
            }
            
            self?.mapViewMode = .defaultView
            
            // 1 set map title from map definition
            self?.delegate?.mapViewController(self!, didUpdateTitle: map.item?.title ?? "Map")
            
            guard let operationalLayers = map.operationalLayers as? [AGSFeatureLayer] else {
                self?.delegate?.mapViewController(self!, shouldAllowNewFeature: false)
                return
            }
            
            AGSLoadObjects(operationalLayers, { [weak self] (_) in
                
                guard operationalLayers.featureAddableLayers.count > 0 else {
                    self?.delegate?.mapViewController(self!, shouldAllowNewFeature: false)
                    return
                }
                
                self?.delegate?.mapViewController(self!, shouldAllowNewFeature: true)
            })
        }
        
        if map.loadStatus == .failedToLoad { map.retryLoad(completion: loadCompletion) }
            
        else { map.load(completion: loadCompletion) }
    }
    
}
