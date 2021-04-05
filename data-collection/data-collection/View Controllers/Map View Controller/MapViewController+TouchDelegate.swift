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

extension MapViewController: AGSGeoViewTouchDelegate {
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        guard mapViewMode == .defaultView || mapViewMode == .selectedFeature(visible: false) || mapViewMode == .selectedFeature(visible: true) else {
            return
        }
        
        query(geoView, atScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    private func query(_ geoView: AGSGeoView, atScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        // Unselect all features and set the map view mode to default.
        clearFeatureSelection()
        mapViewMode = .defaultView
        
        // If an identify operation is running, cancel it.
        identifyOperation?.cancel()
        identifyOperation = nil
        
        // Identify layers for the geo view's tap point.
        identifyOperation = geoView.identifyLayers(atScreenPoint: screenPoint,
                                                   tolerance: 10,
                                                   returnPopupsOnly: true,
                                                   maximumResultsPerLayer: 50) { [weak self] (result, error) in
            
            guard let self = self else { return }
            
            // A successful result will not have an error.
            if let error = error {
                print("[Error] identifying layers", error.localizedDescription)
                self.slideNotificationView.showLabel(withNotificationMessage: "Could not identify features.", forDuration: 2.0)
                self.clearFeatureSelection()
                self.mapViewMode = .defaultView
                return
            }
            
            assert(result != nil, "If there is no error, results must always be returned. Something very wrong happened.")
            
            let identifyResults = result!
            
            // Find identify results for all identifiable feature layers
            // and return them as an array of RichPopups.
            let richPopups = identifyResults.filter {
                AppRules.isLayerIdentifiable($0.layerContent as? AGSFeatureLayer)
            }
            .flatMap { $0.popups.map { RichPopup(popup: $0) } }

            // Inform the user if the identify did not yield any results.
            guard richPopups.count > 0 else {
                self.slideNotificationView.showLabel(withNotificationMessage: "Found no results.", forDuration: 2.0)
                self.clearFeatureSelection()
                self.mapViewMode = .defaultView
                return
            }
            
            self.setSelectedPopups(popups: richPopups)
            
            // Set the map view mode to selected feature
            self.mapViewMode = .selectedFeature(visible: true)
        }
    }
}
