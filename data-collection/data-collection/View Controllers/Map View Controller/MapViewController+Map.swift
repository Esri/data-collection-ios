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
        
        addFeatureButton.isEnabled = false
        
        guard let map = mapView.map else {
            disableMap()
            return
        }
        
        func handleMapLoadCallback(error: Error?) -> Void {
            // If there's an error loading the map we want to inform the user and disable the map.
            if let error = error as NSError? {
                print("[Error: Map Load]", "code: \(error.code)", error.localizedDescription)
                
                if AGSServicesErrorCode(rawValue: error.code) == .tokenRequired, !appContext.isLoggedIn {
                    self.present(signInAlertMessage: "You must sign in to access this resource.")
                }
                else {
                    self.present(simpleAlertMessage: error.localizedDescription)
                }
                
                disableMap()
                return
            }

            // We want to view the new map at the same extent as we had previously seen in the previous map session, essentially picking up where we left off.
            // So, we must determine if the previous session's shared visible area can be applied to the newly loaded map.
            
            // Retrieve a visible area from the previous app session.
            if let sharedVisibleArea = appContext.sharedVisibleArea {
                
                // Is the newly loaded map the offline map?
                if let offlineMap = appContext.offlineMap, offlineMap == map {
                    
                    // Get the initial viewpoint of the offline map
                    if let offlineMapInitialViewpoint = offlineMap.initialViewpoint {
                        
                        // We set the shared the viewpoint to the previous session's shared visible area only if the two extents intersect.
                        // Otherwise, the map loads outside the extent of the offline map, showing a grid in indeterminate space.
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
            self.title = map.item?.title ?? "Map"
            let layers: [AGSFeatureLayer] = map.operationalLayers.compactMap { $0 as? AGSFeatureLayer }
            
            AGSLoadObjects(layers) { [weak self] (_) in
                guard let self = self else { return }
                self.addFeatureButton.isEnabled = !layers.featureAddableLayers.isEmpty
            }
        }
        
        if map.loadStatus == .failedToLoad { map.retryLoad(completion: handleMapLoadCallback) }
            
        else { map.load(completion: handleMapLoadCallback) }
    }
    
    private func disableMap() {
        mapViewMode = .disabled
        title = "No Map"
        addFeatureButton.isEnabled = false
    }
}
