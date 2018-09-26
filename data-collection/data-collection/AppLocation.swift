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

import CoreLocation

/// `AppLocation` handles changes to location authorization not handled by the ArcGIS SDK.
///
/// - Note: Changes to the app's location authorization status can occur while the app
/// is in the background. `AppLocation` processes these changes and exposes a
/// `locationAuthorized: Bool` property that can be observed using KVO.
///
/// - SeeAlso: AppContextChangeHandler.swift
///
@objcMembers class AppLocation: NSObject, CLLocationManagerDelegate {
        
    private let locationManager = CLLocationManager()
    
    dynamic var locationAuthorized: Bool = false

    override init() {
        super.init()
        locationManager.delegate = self
        process()
    }
    
    /// Processes changes to the app's location permission authorization status.
    ///
    /// Location is considered authorized when in use or always.
    ///
    /// - Parameter status: the app's new/changed `CLAuthorizationStatus`.
    ///
    /// - Note: `locationAuthorized` is set true also when `.notDetermined` because setting `mapView.locationDisplay.showLocation`
    /// to true will initiate a request for location permissions via the ArcGIS SDK.
    ///
    private func process(status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()) {
        print("[App Location] Authorization status: \(status)")
        locationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways || status == .notDetermined
    }
    
    // MARK: CLLocationManagerDelegate
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        process(status: status)
    }
}

extension CLAuthorizationStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .authorizedAlways:
            return "Authorized Always"
        case .authorizedWhenInUse:
            return "Authorized When In-Use"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        }
    }
}
