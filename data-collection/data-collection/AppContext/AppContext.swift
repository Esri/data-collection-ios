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

import Foundation
import ArcGIS

extension Notification.Name {
    static let currentPortalDidChange = Notification.Name("currentPortalDidChange")
    static let workModeDidChange = Notification.Name("workModeDidChange")
}

@objcMembers class AppContext: NSObject {
    
    // MARK: Portal
    /**
     The app's current portal.
     
     The portal drives whether the user is logged in or not.
     
     When set, the portal is configured for OAuth authentication so that if login is required, the Runtime SDK and iOS can work together
     to authenticate the current user.
     */
    var portal:AGSPortal = AppConfiguration.buildConfiguredPortal(loginRequired: false) {
        didSet {
            portal.load { [weak self] (error: Error?) in
                
                if let error = error {
                    print("[Error: Portal Load Status]", error.localizedDescription)
                }
                else {
                    print("[Portal] loaded")
                }
                
                guard let strongSelf = self else { return }
                
                let userDescription = strongSelf.portal.user != nil ? "logged in (\(strongSelf.portal.user!.username ?? "no username"))" : "logged out"
                print("[Authentication] user is \(userDescription).")
                
                appNotificationCenter.post(name: .currentPortalDidChange, object: nil)
            }
        }
    }
    
    var isLoggedIn:Bool {
        return portal.user != nil
    }
    
    // MARK: Map
    /**
     The app's current map
     
     The current map is derived from an ArcGIS Online webmap, the same webmap can be taken offline or can be nil.
     `MapViewController` updates the it's AGSMapView's AGSMap upon observed changes.
     */
    dynamic var currentMap: AGSMap?
    
    var isCurrentMapLoaded: Bool {
        return currentMap?.loadStatus == .loaded
    }
    
    /**
     The app's currently loaded offline mobile map package
     
     A reference to the offline mobile map package persists even if the user operates the app in online work mode to signify state.
     A nil `mobileMapPackage` signifies there is no offline mobile map package.
     */
    var mobileMapPackage: LastSyncMobileMapPackage?
    
    var offlineMap: AGSMap? {
        return mobileMapPackage?.maps.first
    }
    
    /**
     An kv-observable boolean value that signifies if the app has a loaded offline `mobileMapPackage`
     */
    dynamic var hasOfflineMap: Bool = false
    
    /**
     The app's current work mode
     
     This property is initialized with the last selected Work mode.
     **Note: The app can have an offline map even in online work mode.
     */
    var workMode: WorkMode = WorkMode.retrieveDefaultWorkMode() {
        didSet {
            workMode.storeDefaultWorkMode()
            appNotificationCenter.post(name: .workModeDidChange, object: nil)
        }
    }
}

