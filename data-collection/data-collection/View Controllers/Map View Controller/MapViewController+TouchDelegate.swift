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
        
        guard mapViewMode == .defaultView || mapViewMode == .selectedFeature(featureLoaded: false) || mapViewMode == .selectedFeature(featureLoaded: true) else {
            return
        }
        
        query(geoView, atScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    private func query(_ geoView: AGSGeoView, atScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {

        // Remove references to current pop-up and set the map view mode to default.
        clearCurrentPopup()
        mapViewMode = .defaultView

        // If an identify operation is running, cancel it.
        identifyOperation?.cancel()
        identifyOperation = nil
        
        // Identify layers for the geo view's tap point.
        identifyOperation = geoView.identifyLayers(atScreenPoint: screenPoint, tolerance: 10, returnPopupsOnly: true, maximumResultsPerLayer: 5) { [weak self] (result, error) in
            
            guard let self = self else { return }
            
            // A successful result will not have an error.
            if let error = error {
                print("[Error] identifying layers", error.localizedDescription)
                self.slideNotificationView.showLabel(withNotificationMessage: "Could not identify features.", forDuration: 2.0)
                self.clearCurrentPopup()
                self.mapViewMode = .defaultView
                return
            }
            
            assert(result != nil, "If there is no error, results must always be returned. Something very wrong happened.")
            
            let identifyResults = result!

            // Find the first layer that is identifiable.
            let firstIdentifiableResult = identifyResults.first(where: { (identifyLayerResult) -> Bool in
                guard let layer = identifyLayerResult.layerContent as? AGSFeatureLayer else { return false }
                return AppRules.isLayerIdentifiable(layer)
            })
            
            // Inform the user if the identify did not yield any results.
            guard let identifyResult = firstIdentifiableResult, identifyResult.popups.count > 0 else {
                self.slideNotificationView.showLabel(withNotificationMessage: "Found no results.", forDuration: 2.0)
                self.clearCurrentPopup()
                self.mapViewMode = .defaultView
                return
            }
            
            // Need to accomodate multiple results
            // - start by displaying all those results
            // - as user selects new result from displayed list, update selection in MapView
            self.setSelectedPopups(popups: identifyResult.popups.map({ (popup) -> RichPopup in
                return RichPopup(popup: popup)
            }))
            
            self.clearCurrentPopup()
            
//            // Use the geometry engine to determine the nearest pop-up to the touch point.
//            if let nearest = identifyResult.popups.popupNearestTo(mapPoint: mapPoint) {
//                let richPopup = RichPopup(popup: nearest)
//                self.setCurrentPopup(popup: richPopup)
//            }
//            else {
//                self.clearCurrentPopup()
//            }
            
            // Set the map view mode to selected feature
            self.mapViewMode = .selectedFeature(featureLoaded: false)
            
//            // Load the new current pop up
//            self.refreshCurrentPopup()
        }
    }
}
