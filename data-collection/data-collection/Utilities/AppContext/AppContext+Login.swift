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
    
    // TODO consider a chain of startup events with this function before loading a local map
    
    // MARK: Portal Auth
    /**
     We want to try to log in to the portal with cached credentials from our last session.
     */
    func attemptLoginToPortalFromCredentials() {
        
        // We'll temporarily disable prompting the user to log in in case the cached credentials are not suitable to log us in.
        // I.e. if the cached credentials aren't good enough to find ourselves logged in to the portal/ArcGIS Online, then just
        // accept it and don't prompt us to log in, resulting in a Portal being accessed anonymously.
        // We revert from that behaviour as soon as the portal loads below.
        let authenticationRequiredPortal = AGSPortal(loginRequired: true)
        let authenticationRequiredPortalRequestConfiguration = authenticationRequiredPortal.requestConfiguration
        let silentAuthenticationRequestConfiguration = (authenticationRequiredPortalRequestConfiguration ?? AGSRequestConfiguration.global()).copy() as? AGSRequestConfiguration
        silentAuthenticationRequestConfiguration?.shouldIssueAuthenticationChallenge = { _ in return false }
        authenticationRequiredPortal.requestConfiguration = silentAuthenticationRequestConfiguration
        authenticationRequiredPortal.load() { [weak self] error in
            // Before we do anything else, go back to handling auth challenges as before.
            authenticationRequiredPortal.requestConfiguration = authenticationRequiredPortalRequestConfiguration
            // If we were able to log in with cached credentials, there will be no error.
            if let error = error {
                // If we were not able to log in with cached credentials, we will set `loginRequired` to `false` thus allowing unauthenticated users to consume the map (but not edit!)
                print("[Error] loading the new fake portal, user is not authenticated: \(error.localizedDescription)")
                self?.portal = AGSPortal(loginRequired: false)
            }
            else {
                self?.portal = AGSPortal(loginRequired: true)
            }
        }
    }
    
    func login() {
        guard !isLoggedIn else {
            return
        }
        // Setting `loginRequired` to `true` will force a login prompt to present.
        portal = AGSPortal(loginRequired: true)
    }
    
    func logout() {
        guard isLoggedIn else {
            return
        }
        // We want to remove cached credentials upon logout.
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        // Setting `loginRequired` to `false` will allow unauthenticated users to consume the map (but not edit!)
        portal = AGSPortal(loginRequired: false)
    }
}
