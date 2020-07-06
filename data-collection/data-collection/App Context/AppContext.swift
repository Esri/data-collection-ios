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

/// The `AppContext` maintains the app's current state.
///
/// Primarily, the `AppContext` is responsible for:
/// * Authentication and user lifecyle management.
/// * Loading AGSMaps from an AGSPortal or an offline AGSMobileMapPackage.
/// * Managing online and offline work modes.

class AppContext: NSObject {
    
    // MARK: Portal
    
    /// The app's current portal.
    ///
    /// The portal drives whether the user is signed in or not.
    ///
    /// When set, the portal is configured for OAuth authentication so that if login is required,
    /// the Runtime SDK and iOS can work together to authenticate the current user.
    var portal:AGSPortal = AGSPortal.configuredPortal(loginRequired: false) {
        didSet {
            portal.load { [weak self] (error: Error?) in
                
                guard let self = self else { return }
                
                defer {
                    NotificationCenter.default.post(self.portalNotification)
                }
                
                if let error = (error as NSError?),
                    self.workMode == .online && error.code != NSUserCancelledError {
                    self.currentMap = nil
                    return
                }

                if self.isLoggedIn {
                    print("[Portal] user is signed in")
                }
                else {
                    print("[Portal] user is signed out")
                }
                
                if self.workMode == .online {
                    self.setWorkModeOnlineWithMapFromPortal()
                }
            }
        }
    }
    
    var isLoggedIn:Bool {
        return portal.user != nil
    }
    
    // MARK: Map
    
    /// The app's current map.
    ///
    /// The current map is derived from a portal web map, the same web map can be taken offline or can be nil.
    ///
    /// - Note: `MapViewController` updates its AGSMapView's AGSMap upon observed changes.
    var currentMap: AGSMap? {
        didSet {
            NotificationCenter.default.post(currentMapNotification)
        }
    }
    
    var isCurrentMapLoaded: Bool {
        return currentMap?.loadStatus == .loaded
    }
    
    // MARK: Offline Map
    
    /// The app's currently downloaded offline mobile map package.
    ///
    /// - Note: A reference to the offline mobile map package persists even if the user operates the app in online work mode to signify state.
    /// - Note: A nil `mobileMapPackage` signifies there is no offline mobile map package currently downloaded to the device.
    var mobileMapPackage: LastSyncMobileMapPackage?
    
    var offlineMap: AGSMap? {
        return mobileMapPackage?.maps.first
    }
    
    /// A kv-observable boolean value that signifies if the app has a downloaded offline `mobileMapPackage`.
    var hasOfflineMap: Bool = false {
        didSet {
            NotificationCenter.default.post(hasOfflineMapNotification)
        }
    }
    
    /// The app's current work mode.
    ///
    /// This property is initialized with the work mode from the user's last session.
    ///
    /// - Note: The app can have an offline map even when working online.
    var workMode: WorkMode = WorkMode.retrieveDefaultWorkMode() {
        didSet {
            workMode.storeDefaultWorkMode()
            NotificationCenter.default.post(workModeNotification)
        }
    }
}

// MARK:- Notification Center

extension Notification.Name {
    static let portalDidChange = Notification.Name("portalDidChange")
    static let workModeDidChange = Notification.Name("workModeDidChange")
    static let hasOfflineMapDidChange = Notification.Name("hasOfflineMapDidChange")
    static let currentMapDidChange = Notification.Name("currentMapDidChange")
}

extension AppContext {
    
    var portalNotification: Notification {
        Notification(
            name: .portalDidChange,
            object: self,
            userInfo: nil
        )
    }
    
    var workModeNotification: Notification {
        Notification(
            name: .workModeDidChange,
            object: self,
            userInfo: nil
        )
    }
    
    var hasOfflineMapNotification: Notification {
        Notification(
            name: .hasOfflineMapDidChange,
            object: self,
            userInfo: nil
        )
    }
    
    var currentMapNotification: Notification {
        Notification(
            name: .currentMapDidChange,
            object: self,
            userInfo: nil
        )
    }
}
