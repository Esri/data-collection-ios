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

extension AGSPortal {
    
    /// Returns an `AGSPortal` that is signed in if cached credentials allow.
    ///
    /// The credential cache will have at most one valid cached credential. It is used to sign in to the portal if possible.
    ///
    /// If cached credentials do not automatically sign in to the portal, then connect to
    /// the portal anonymously (i.e. not signed in).
    ///
    /// Use a custom portal URL if provided, otherwise use ArcGIS Online.
    ///
    /// - Parameters:
    ///   - portalURL: A URL to a custom portal. If nil, ArcGIS Online is used.
    ///   - completion: A block that receives the AGSPortal and a Bool. The Bool is true if the portal could be signed in to using cached credentials, or false otherwise.
    
    static func bestPortalFromCachedCredentials(portalURL: URL, completion: @escaping ((AGSPortal, Bool) -> Void)) {
        // First try a portal that requires a login. If there are cached credentials that suit,
        // then in the portal.load() callback below we will find ourselves signed in to the portal.
        let newPortal = AGSPortal(url: portalURL, loginRequired: true)
        
        // We'll temporarily disable prompting the user to sign in in case the cached credentials are not suitable to sign us in.
        // I.e. if the cached credentials aren't good enough to find ourselves signed in to the portal/ArcGIS Online, then just
        // accept it and don't prompt us to sign in, resulting in a Portal being accessed anonymously.
        // We revert from that behaviour as soon as the portal loads below.
        let originalPortalRC = newPortal.requestConfiguration
        let sourceRC = originalPortalRC ?? AGSRequestConfiguration.global()
        let silentAuthRC = sourceRC.copy() as? AGSRequestConfiguration
        
        silentAuthRC?.shouldIssueAuthenticationChallenge = { _ in return false }
        
        newPortal.requestConfiguration = silentAuthRC
        
        newPortal.load() { error in
            // Before we do anything else, go back to handling auth challenges as before.
            newPortal.requestConfiguration = originalPortalRC
            
            // If we were able to sign in with cached credentials, there will be no error.
            if error == nil {
                completion(newPortal, true)
            } else {
                // Could not sign in silently with cached credentials, so let's return a portal that doesn't require login
                print("[Error: Portal] couldn't load the new portal: \(error!.localizedDescription)")
                guard let newURL = newPortal.url else {
                    // Fall back to ArcGIS Online
                    completion(AGSPortal.arcGISOnline(withLoginRequired: false), false)
                    return
                }
                
                // Portal URL was specified. Let's use that.
                completion(AGSPortal(url: newURL, loginRequired: false), false)
            }
        }
    }
}
