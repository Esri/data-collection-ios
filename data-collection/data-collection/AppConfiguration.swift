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
import ArcGIS

extension URL {
    /// The URL to the base portal.
    /// - Note: A `fatalError` is thrown if a URL can't be built from the configuration.
    static let basePortal: URL = {
        guard let url = URL(string: "https://\(String.basePortalDomain)") else {
            fatalError("App Configuration must contain a valid portal service url.")
        }
        return url
    }()
    
    /// The URL to the world geocode service.
    /// Swap out for another geocoder server if you prefer.
    /// - Note: A `fatalError` is thrown if a URL can't be built from the configuration.
    static let geocodeService: URL = {
        guard let url = URL(string: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer") else {
            fatalError("App Configuration must contain a valid geocode service url.")
        }
        return url
    }()
}

extension String {
    /// The ID of your portal's [web map](https://runtime.maps.arcgis.com/home/item.html?id=16f1b8ba37b44dc3884afc8d5f454dd2).
    static let webMapItemID = "16f1b8ba37b44dc3884afc8d5f454dd2"
    
    /// The base portal's domain.
    /// This is used to both build a `URL` to your portal as well as the base URL string used to check reachability.
    /// - Note: exclude `http` or `https`, this is configured in `basePortalURL`.
    static let basePortalDomain = "www.arcgis.com"
    
    /// Used by the shared `AGSAuthenticationManager` to auto synchronize cached credentials to the device's keychain.
    static let keychainIdentifier: String = "\(Bundle.main.bundleIdentifier!).keychain"
}

enum OAuth {
    /// The App's oAuth redirect URL.
    /// - The URL must match the path created in the **Current Redirect URIs** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    static let redirectUrl: String = "data-collection://auth"
    
    /// The App's full oAuth redirect URL as a `URLComponents` object.
    static let components: URLComponents = {
        guard let components = URLComponents(string: redirectUrl) else {
            fatalError("OAuth.redirectUrl must contain a valid URL.")
        }
        return components
    }()
}


extension AGSPortal {
    
    // MARK: Portal From Configuration

    static func configuredPortal(loginRequired: Bool) -> AGSPortal {
        AGSPortal(url: .basePortal, loginRequired: loginRequired)
    }
    
    // MARK: Configured Portal Item
    
    var configuredPortalItem: AGSPortalItem {
        AGSPortalItem(portal: self, itemID: .webMapItemID)
    }

    // MARK: Configured Map
    var configuredMap: AGSMap {
        let map = AGSMap(item: configuredPortalItem)
        map.load(completion: nil)
        return map
    }
}

