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
    /**
     Returns an AGSPortal that is logged in if cached credentials allow.
     
     - Parameters:
     - portalURL: A URL to a custom portal. If nil, ArcGIS Online is used.
     - completion: A block that receives the AGSPortal and a Bool. The Bool is true if the portal could be logged in to using cached credentials, or false otherwise.
     */
    static func bestPortalFromCachedCredentials(portalURL: URL?, completion: @escaping ((AGSPortal, Bool) -> Void)) {
        // The credential cache will have at most one valid cached credential. We want to see if it will log us into the portal.
        //
        // If a custom portal URL is provided, we'll use that, but otherwise we'll use ArcGIS Online.
        //
        // If we don't have cached credentials that automatically log us in to that portal, then we connect to
        // the portal anonymously (i.e. not logged in).
        
        // First try a portal that requires a login. If there are cached credentials that suit,
        // then in the portal.load() callback below we will find ourselves logged in to the portal.
        let newPortal = (portalURL != nil) ? AGSPortal(url: portalURL!, loginRequired: true) : AGSPortal.arcGISOnline(withLoginRequired: true)
        
        // We'll temporarily disable prompting the user to log in in case the cached credentials are not suitable to log us in.
        // I.e. if the cached credentials aren't good enough to find ourselves logged in to the portal/ArcGIS Online, then just
        // accept it and don't prompt us to log in, resulting in a Portal being accessed anonymously.
        // We revert from that behaviour as soon as the portal loads below.
        let originalPortalRC = newPortal.requestConfiguration
        let sourceRC = originalPortalRC ?? AGSRequestConfiguration.global()
        let silentAuthRC = sourceRC.copy() as? AGSRequestConfiguration
        
        silentAuthRC?.shouldIssueAuthenticationChallenge = { _ in return false }
        
        newPortal.requestConfiguration = silentAuthRC
        
        newPortal.load() { error in
            // Before we do anything else, go back to handling auth challenges as before.
            newPortal.requestConfiguration = originalPortalRC
            
            // If we were able to log in with cached credentials, there will be no error.
            if error == nil {
                completion(newPortal, true)
            } else {
                // Could not log in silently with cached credentials, so let's return a portal that doesn't require login
                print("Error loading the new portal: \(error!.localizedDescription)")
                if let newURL = newPortal.url {
                    // Portal URL was specified. Let's use that.
                    completion(AGSPortal(url: newURL, loginRequired: false), false)
                } else {
                    // Fall back to ArcGIS Online
                    completion(AGSPortal.arcGISOnline(withLoginRequired: false), false)
                }
            }
        }
    }
}
