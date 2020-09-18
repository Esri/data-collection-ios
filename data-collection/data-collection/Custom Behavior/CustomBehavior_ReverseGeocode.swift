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

/// Behavior specific to the _Trees of Portland_ web map.
///
/// When creating a new tree, this function uses a geocoder to reverse-geocode an address, provided a point.
///
/// - Parameters:
///     - popup: The new tree.
///     - point: The point used to reverse-geocode for an address.
///     - completion: The callback called upon completion. The operation finishes successfully or fails, silently.
func enrich(popup: AGSPopup, withReverseGeocodedDataForPoint point: AGSPoint, completion: @escaping () -> Void) {
    
    let addressKey = "Address"
    
    // Use the geocoder to reverse geocode an address from a point.
    // If the app is working online, the world geocoder service is used.
    // If the app is working offline, the side loaded geocoder is used.
    appContext.addressLocator.reverseGeocodeAddress(for: point) { result  in
        switch result {
        case .success(let address):
            if popup.geoElement.attributes[addressKey] != nil {
                popup.geoElement.attributes[addressKey] = address
            }
        case .failure(let error):
            print("[Error: Reverse Geocode]", error.localizedDescription)
        }
        
        completion()
    }
}
