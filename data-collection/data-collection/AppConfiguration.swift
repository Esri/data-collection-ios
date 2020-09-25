// Copyright 2017 Esri
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

import ArcGIS

// MARK:- Configurable

// MARK: 1. Portal & Web Map

enum PortalConfig {
    /// The base URL (`String`) to your portal.
    static let basePortalDomain = "www.arcgis.com"
    /// The ID of your portal's [web map](https://runtime.maps.arcgis.com/home/item.html?id=16f1b8ba37b44dc3884afc8d5f454dd2).
    static let webMapItemID = "16f1b8ba37b44dc3884afc8d5f454dd2"
}

// MARK: 2. OAuth Redirect URL

enum OAuthConfig {
    /// The App's oAuth redirect URL.
    /// - The URL must match the path created in the **Current Redirect URIs** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    static let redirectUrl = "data-collection://auth"
}

// MARK: 3. Address Locator

enum OnlineGeocoderConfig {
    /// The URL (`String`) to the world geocode service.
    /// Swap out for another geocoder server if you prefer.
    static let urlString = "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"
    /// The geocoder's `AGSGeocodeResult` address attribute key.
    static let addressAttributeKey = "Address"
}

enum OfflineGeocoderConfig {
    /// The name of your side-loaded offline Locator.
    static let name = "AddressLocator"
    /// The geocoder's `AGSGeocodeResult` address attribute key.
    static let addressAttributeKey = "Match_addr"
}

// MARK:- Not Configurable, DO NOT TOUCH!

extension URL {
    /// The URL to the base portal.
    /// - Note: A `fatalError` is thrown if a URL can't be built from the configuration.
    static let basePortal: URL = {
        guard let url = URL(string: String(format: "https://%@", PortalConfig.basePortalDomain)) else {
            fatalError("App Configuration must contain a valid portal service url.")
        }
        return url
    }()
}

extension OAuthConfig {
    /// The App's full oAuth redirect URL as a `URLComponents` object.
    static let components: URLComponents = {
        guard let components = URLComponents(string: redirectUrl) else {
            fatalError("OAuth.redirectUrl must contain a valid URL.")
        }
        return components
    }()
}

extension OnlineGeocoderConfig {
    /// The URL to the world geocode service.
    /// - Note: A `fatalError` is thrown if a URL can't be built from the configuration.
    static let url: URL = {
        guard let url = URL(string: OnlineGeocoderConfig.urlString) else {
            fatalError("App Configuration must contain a valid geocode service url.")
        }
        return url
    }()
}
