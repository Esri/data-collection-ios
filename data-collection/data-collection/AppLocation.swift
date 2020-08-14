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

/// `AppLocation` handles changes to location authorization not handled by the SDK.
///
/// - Note: Changes to the app's location authorization status can occur while the app
/// is in the background. `AppLocation` processes these changes and exposes a
/// `locationAuthorized: Bool` property that can be observed using KVO.
///
class AppLocation: NSObject {
        
    private let locationManager = CLLocationManager()
    
    /// Location is considered authorized when in use or always.
    /// - Parameter status: the app's new/changed `CLAuthorizationStatus`.
    ///
    /// - Note: `locationAuthorized` is also set true when `CLAuthorizationStatus` is `.notDetermined` because setting `mapView.locationDisplay.showLocation`
    /// to true will initiate a request for location permissions via the Runtime SDK.
    var locationAuthorized: Bool {
        let status = CLLocationManager.authorizationStatus()
        return
            status == .authorizedWhenInUse ||
            status == .authorizedAlways ||
            status == .notDetermined
    }

    override init() {
        super.init()
        locationManager.delegate = self
    }
}

// MARK:- Location Manager Delegate

extension AppLocation: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("[AppLocation] did change status \(status)")
        NotificationCenter.default.post(locationAuthorizationNotification)
    }
}

// MARK:- Notification Center

extension Notification.Name {
    static let locationAuthorizationDidChange = Notification.Name("locationAuthorizationDidChange")
}

extension AppLocation {
    var locationAuthorizationNotification: Notification {
        Notification(
            name: .locationAuthorizationDidChange,
            object: self,
            userInfo: nil
        )
    }
}

// MARK:- Custom String Convertible
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
        @unknown default:
            fatalError("Unsupported case \(self).")
        }
    }
}
