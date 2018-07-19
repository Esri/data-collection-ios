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

@objcMembers class AppLocation: NSObject, CLLocationManagerDelegate {
        
    private let locationManager = CLLocationManager()
    
    dynamic var locationAuthorized: Bool = false

    override init() {
        super.init()
        locationManager.delegate = self
        process()
    }
    
    private func process(status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()) {
        print("[App Location] authorization status: \(status)")
        locationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways || status == .notDetermined
    }
    
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
