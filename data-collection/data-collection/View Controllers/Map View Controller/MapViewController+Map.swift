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
        
        guard let map = mapView.map else {
            
            mapViewMode = .disabled
            delegate?.mapViewController(self, didUpdateTitle: "No Map")
            delegate?.mapViewController(self, shouldAllowNewFeature: false)
            return
        }
        
        let loadCompletion: ((Error?) -> Void)? = { [weak self] (error) in
            
            guard let self = self else { return }
            
            guard error == nil else {
                let error = (error! as NSError)

                print("[Error: Map Load]", "code: \(error.code)", error.localizedDescription)
                
                if AGSServicesErrorCode(rawValue: error.code) == .tokenRequired, !appContext.isLoggedIn {
                    self.present(loginAlertMessage: "You must log in to access this resource.")
                }
                else {
                    self.present(simpleAlertMessage: error.localizedDescription)
                }
                
                self.mapViewMode = .disabled
                return
            }

            // We want to apply the previous session's shared visible area (the extent of the map view) to the newly loaded map.
            // So, we must determine if the previous session's shared visible area can be applied to the newly loaded map.
            // Retrieve a visible area from the previous app session.
            if let sharedVisibleArea = appContext.sharedVisibleArea {
                
                // Is the newly loaded map the offline map?
                if let offlineMap = appContext.offlineMap, offlineMap == map {
                    
                    // Get the initial viewpoint of the offline map
                    if let offlineMapInitialViewpoint = offlineMap.initialViewpoint {
                        
                        // If the previous session's shared visible area intersects with the offline map's geometry, we can set
                        if AGSGeometryEngine.geometry(offlineMapInitialViewpoint.targetGeometry, intersects: sharedVisibleArea.targetGeometry) {
                            self.mapView.setViewpoint(sharedVisibleArea)
                        }
                    }
                }
                else {
                    // Because the newly loaded map is an online map and has no defined extent,
                    // we can safely set the viewpoint from the previous session's shared visible area.
                    self.mapView.setViewpoint(sharedVisibleArea)
                }
            }
            
            self.mapViewMode = .defaultView
            
            self.delegate?.mapViewController(self, didUpdateTitle: map.item?.title ?? "Map")
            
            guard let operationalLayers = map.operationalLayers as? [AGSFeatureLayer] else {
                self.delegate?.mapViewController(self, shouldAllowNewFeature: false)
                return
            }
            
            AGSLoadObjects(operationalLayers, { [weak self] (_) in
                guard let self = self else { return }
                
                let flag = !operationalLayers.featureAddableLayers.isEmpty
                self.delegate?.mapViewController(self, shouldAllowNewFeature: flag)
            })
        }
        
        if map.loadStatus == .failedToLoad { map.retryLoad(completion: loadCompletion) }
            
        else { map.load(completion: loadCompletion) }
    }
    
}
