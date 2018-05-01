//// Copyright 2017 Esri
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

import UIKit

var appDelegate: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
}

var appReachability: NetworkReachabilityManager {
    return appDelegate.reachabilityManager
}

var appContext: AppContext {
    return AppContext.shared
}

var appBundleID: String {
    return Bundle.main.bundleIdentifier!
}

var appNotificationCenter: NotificationCenter {
    return NotificationCenter.default
}

// TODO, reintroduced Geocoder.
var appReverseGeocoder: ReverseGeocoderManager {
    return appContext.reverseGeocoderManager
}
