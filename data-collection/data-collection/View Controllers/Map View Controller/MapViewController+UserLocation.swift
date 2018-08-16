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
    
    func userRequestsZoomOnUserLocation() {
        
        guard mapViewMode != .disabled else {
            return
        }
        
        if appLocation.locationAuthorized {
            guard mapView.locationDisplay.showLocation == true, let location = mapView.locationDisplay.location, let position = location.position else {
                return
            }
            let viewpoint = AGSViewpoint(center: position, scale: 2500)
            mapView.setViewpoint(viewpoint, duration: 1.2, completion: nil)
        }
        else {
            present(settingsAlertMessage: "You must enable Data Collection to access your location in your device's settings to zoom to your location.")
        }
    }
    
    func adjustForLocationAuthorizationStatus() {
        
        mapView.locationDisplay.showLocation = appLocation.locationAuthorized
        mapView.locationDisplay.showAccuracy = appLocation.locationAuthorized
        
        if appLocation.locationAuthorized {
            mapView.locationDisplay.start { (err) in
                if let error = err {
                    print("[Error] Cannot display user location: \(error.localizedDescription)")
                }
            }
        }
        else {
            mapView.locationDisplay.stop()
        }
    }
}
