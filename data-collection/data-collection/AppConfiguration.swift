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
    static let basePortalURL: URL = {
        guard let url = URL(string: "https://\(String.basePortalDomain)") else {
            fatalError("App Configuration must contain a valid portal service url.")
        }
        return url
    }()
    
    /// The URL to the world geocode service.
    /// Swap out for another geocoder server if you prefer.
    /// - Note: A `fatalError` is thrown if a URL can't be built from the configuration.
    static let geocodeServiceURL: URL = {
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
    
    /// The App's URL scheme.
    /// - The URL scheme must match the scheme in the **Current Redirect URIs** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    /// - The URL scheme must match the URL scheme in the **URL types** of the Xcode project configuration.
    static let urlScheme: String = "data-collection"
    
    /// The App's URL auth path.
    /// - The URL scheme must match the path in the **Current Redirect URIs** section of the **Authentication** tab within the Dashboard of the Developers site.
    static let urlAuthPath: String = "auth"
    
    /// The App's full oAuth redirect url path.
    /// - Note: The path is built using the above configured `urlScheme` and `urlAuthPath`. E.g. `data-collection://auth`.
    static let oAuthRedirectURLString: String = "\(urlScheme)://\(urlAuthPath)"
    
    /// Used by the shared `AGSAuthenticationManager` to auto synchronize cached credentials to the device's keychain.
    static let keychainIdentifier: String = "\(appBundleID).keychain"
    
    /// Your organization's ArcGIS Runtime [license](https://developers.arcgis.com/arcgis-runtime/licensing/) key.
    /// - This step is optional during development but required for deployment.
    /// - Licensing the app will remove the "Licensed for Developer Use Only" watermark on the map view.
    static let licenseKey: String = "your_license_key"
    
    /// The App's public client ID.
    /// - The client ID is used by oAuth to authenticate a user.
    /// - The client ID can be found in the **Credentials** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    /// - Note: Change this to reflect your organization's client ID.
    static let clientID: String = "h3em0ifYNGfz3uHX"
}

// MARK: Portal From Configuration

extension AGSPortal {
    
    /// Build an `AGSPortal` based on the app's configuration.
    /// - Parameter loginRequired: `false` if you intend to access the portal anonymously. `true` if you want to use a credential (the ArcGIS Runtime SDK will present a modal login web view if needed).
    /// - Returns: A new configured `AGSPortal`.
    static func configuredPortal(loginRequired: Bool) -> AGSPortal {
        return AGSPortal(url: .basePortalURL, loginRequired: loginRequired)
    }
}
