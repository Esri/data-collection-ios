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

extension AppContext {
    
    /// Try to log in to the AppContext's current portal, if possible.
    func logInCurrentPortalIfPossible() {
        // Try to take the current portal and update it to be in a logged in state.
        portal.load() { error in
            guard error == nil else {
                print("[Error: AGSPortal] loading the portal during login attempt: \(error!.localizedDescription)")
                return
            }
            
            // Only try logging in if the current portal isn't logged in (user == nil)
            // That is, we got here because the AGSAuthenticationManager is being called back from some in-line OAuth
            // success based off a call to a service (an explicit login would set portal.user != nil).
            if let portalURL = appContext.portal.url, appContext.portal.user == nil {
                AGSPortal.bestPortalFromCachedCredentials(portalURL: portalURL) { newPortalInstance, didLogIn in
                    if didLogIn {
                        // Finally update the current portal if we managed to log in.
                        appContext.portal = newPortalInstance
                    }
                }
            }
        }
    }
    
    /// Trigger a log in sequence to a portal by building a portal where `loginRequired` is `true`.
    ///
    /// - Note: The ArcGIS Runtime SDK will present a modal login web view if it cannot find any suitable cached credentials.
    func login() { 
        // Setting `loginRequired` to `true` will force a login prompt to present.
        portal = AppConfiguration.buildConfiguredPortal(loginRequired: true)
    }
    
    /// Log out in the app and from the portal.
    ///
    /// The app does this by removing all cached credentials and no longer requiring authentication in the portal.
    func logout() {
        // We want to remove cached credentials upon logout.
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        // Setting `loginRequired` to `false` will allow unauthenticated users to consume the map (but not edit!)
        portal = AppConfiguration.buildConfiguredPortal(loginRequired: false)
    }
}
