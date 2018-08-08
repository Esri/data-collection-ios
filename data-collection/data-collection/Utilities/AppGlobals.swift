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

let appReachability: NetworkReachabilityManager = {
    
    let manager = NetworkReachabilityManager(host: AppConfiguration.basePortalDomain)
    assert(manager != nil, "Network Reachability Manager must be constructed a valid service url.")
    
    manager!.listener = { status in
        print("[Reachability] Network status changed: \(status)")
        appNotificationCenter.post(AppNotifications.reachabilityChanged)
    }
    
    manager!.startListening()
    
    return manager!
}()

let appLocation = AppLocation()

let appContext = AppContext()

var appBundleID: String {
    return Bundle.main.bundleIdentifier!
}

var appNotificationCenter: NotificationCenter {
    return NotificationCenter.default
}

let appReverseGeocoder = ReverseGeocoderManager()

let appColors = AppColors()

let appFonts = AppFonts()
