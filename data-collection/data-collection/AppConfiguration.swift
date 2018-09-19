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

class AppConfiguration {
    
    /// The id of your portal's web map.
    static let webMapItemID = "fcc7fc65bb96464c9c0986576c119a92"
    
    /// The base portal's domain.
    /// This is used to both build a `URL` to your portal as well as the base URL string used to check reachability.
    /// - Note: exclude `http` or `https`, this is configured in `basePortalURL`.
    static let basePortalDomain = "www.arcgis.com"
    
    /// The URL to the base portal.
    /// - Note: A `fatalError` is thrown if a URL can't be built from the configuration.
    static let basePortalURL: URL = {
        guard let url = URL(string: "https://\(basePortalDomain)") else {
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
    
    /// The App's URL scheme.
    /// - The URL scheme must match the scheme in the **Current Redirect URIs** section of the Authentication tab within the Dashboard of the Developers site.
    /// - The URL scheme must match the URL scheme in the **URL types** of the Xcode project configuration.
    static let urlScheme: String = "data-collection"
    
    /// The App's URL auth path.
    /// - The URL scheme must match the path in the **Current Redirect URIs** section of the Authentication tab within the Dashboard of the Developers site.
    static let urlAuthPath: String = "auth"
    
    /// The App's full oAuth redirect url path.
    /// - Note: the path is built using the above configured `urlScheme` and `urlAuthPath`.
    static let oAuthRedirectURLString: String = "\(urlScheme)://\(urlAuthPath)"
    
    /// Used by the shared `AGSAuthenticationManager` to auto synchronize cached credentials to the device's keychain.
    static let keychainIdentifier: String = "\(appBundleID).keychain"
    
    /// License the app by configuring with your organization's [license](https://developers.arcgis.com/arcgis-runtime/licensing/) key.
    /// - Note: This step is optional during development but required for deployment. Licensing the app will remove the "Licensed for Developer Use Only" watermark on the map view.
    static let licenseKey: String = "fake_license_key"
    
    /// The App's public client ID.
    /// The client ID is used by oAuth to authenticate a user.
    static let clientID: String = "h3em0ifYNGfz3uHX"
}

// MARK: Portal From Configuration

extension AppConfiguration {
    
    /// Builds a portal based on the app's configuration.
    /// - Parameter loginRequired: Whether or not you intend to access the portal anonymously or if you want to use a credential.
    /// - Returns: A new configured `AGSPortal`.
    static func buildConfiguredPortal(loginRequired: Bool) -> AGSPortal {
        return AGSPortal(url: basePortalURL, loginRequired: loginRequired)
    }
}
