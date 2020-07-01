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
    
    /// Your organization's ArcGIS Runtime [license](https://developers.arcgis.com/arcgis-runtime/licensing/) key.
    ///
    /// - Add your license key:
    ///   - click **Product** -> **Scheme** -> **Edit Scheme**
    ///   - select **Run** -> **Arguments**
    ///   - add **Environment Variable**:
    ///       - name: `"ARCGIS_LICENSE_KEY"`
    ///       - value: `"your-license-key"`
    ///
    /// _Note, this step is optional during development but required for deployment._
    /// Licensing the app will remove the "Licensed for Developer Use Only" watermark on the map view.
    ///
    static let licenseKey: String = {
        let licenseKeyEnvironmentKey = "ARCGIS_LICENSE_KEY"
        guard let licenseKey = ProcessInfo.processInfo.environment[licenseKeyEnvironmentKey] else {
            #if DEBUG
            return "fake_inconsequential_license_key"
            #else
            fatalError("Scheme must include \"\(licenseKeyEnvironmentKey)\" environment variable.")
            #endif
        }
        return licenseKey
    }()
    
    /// The App's public client ID.
    ///
    /// The client ID is used by oAuth to authenticate a user.
    ///
    /// - Add your client ID:
    ///   - click **Product** -> **Scheme** -> **Edit Scheme**
    ///   - select **Run** -> **Arguments**
    ///   - add **Environment Variable**:
    ///       - name: `"ARCGIS_CLIENT_ID"`
    ///       - value: `"your-client-id"`
    ///
    /// _Note, change this to reflect your organization's client ID._
    /// The client ID can be found in the **Credentials** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    ///
    static let clientID: String = {
        let clientIDEnvironmentKey = "ARCGIS_CLIENT_ID"
        guard let clientID = ProcessInfo.processInfo.environment[clientIDEnvironmentKey] else {
            fatalError("Scheme must include \"\(clientIDEnvironmentKey)\" environment variable.")
        }
        return clientID
    }()
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

// MARK: Portal From Configuration

extension AGSPortal {
    
    /// Build an `AGSPortal` based on the app's configuration.
    /// - Parameter loginRequired: `false` if you intend to access the portal anonymously. `true` if you want to use a credential (the ArcGIS Runtime SDK will present a modal login web view if needed).
    /// - Returns: A new configured `AGSPortal`.
    static func configuredPortal(loginRequired: Bool) -> AGSPortal {
        return AGSPortal(url: .basePortal, loginRequired: loginRequired)
    }
}
