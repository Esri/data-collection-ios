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
        query(geoView, atScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    private func query(_ geoView: AGSGeoView, atScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        guard mapViewMode != .disabled else {
            return
        }

        currentPopup = nil
        
        identifyOperation?.cancel()
        identifyOperation = nil
        
        identifyOperation = geoView.identifyLayers(atScreenPoint: screenPoint, tolerance: 8, returnPopupsOnly: true, maximumResultsPerLayer: 5) { [weak self] (result, error) in
            
            if let error = error {
                print("[Error] identifying layers", error.localizedDescription)
                self?.notificationBar.showLabel(withNotificationMessage: "Could not identify features.", forDuration: 2.0)
                self?.currentPopup = nil
                return
            }
            
            guard let identifyResults = result else {
                print("[Error] identifying layers, missing results")
                self?.notificationBar.showLabel(withNotificationMessage: "Could not identify features.", forDuration: 2.0)
                self?.currentPopup = nil
                return
            }
            
            var firstIdentifiableResult: AGSIdentifyLayerResult?
            
            for identifyResult in identifyResults {
                
                guard
                    let featureLayer = identifyResult.layerContent as? AGSFeatureLayer,
                    featureLayer.isIdentifiable
                    else {
                        continue
                }
                
                firstIdentifiableResult = identifyResult
                break
            }
            
            guard let identifyResult = firstIdentifiableResult else {
                print("[Error] no found feature layer meets criteria")
                self?.notificationBar.showLabel(withNotificationMessage: "Found no results.", forDuration: 2.0)
                self?.currentPopup = nil
                return
            }
            
            guard identifyResult.popups.count > 0 else {
                print("[Identify Layer] Found no results")
                self?.notificationBar.showLabel(withNotificationMessage: "Found no results.", forDuration: 2.0)
                self?.currentPopup = nil
                return
            }
            
            self?.currentPopup = identifyResult.popups.popupNearestTo(mapPoint: mapPoint)
        }
    }
}
