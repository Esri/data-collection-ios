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
    
    static let webMapItemID = "fcc7fc65bb96464c9c0986576c119a92"
    
    static let basePortalDomain = "www.arcgis.com"
    
    static let basePortalURL: URL = {
        let url = URL(string: "https://\(basePortalDomain)")
        assert(url != nil, "App Configuration must contain a valid portal service url.")
        return url!
    }()
    
    static let geocodeServiceURL: URL = {
        let url = URL(string: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")
        assert(url != nil, "App Configuration must contain a valid geocode service url.")
        return url!
    }()
    
    static let urlScheme: String = "data-collection"
    static let urlAuthPath: String = "auth"
    static let oAuthRedirectURLString: String = "\(urlScheme)://\(urlAuthPath)"
    
    static let keychainIdentifier: String = "\(appBundleID).keychain"
    
    static let licenseKey: String = "fake_license_key"
    static let clientID: String = "AaXxKoHH3piT1fe3"
}

// MARK: Debug Request Logging

extension AppConfiguration {
    
    static var logRequests: Bool {
        set {
            #if DEBUG
            AGSRequestConfiguration.global().debugLogRequests = newValue
            #else
            print("Debug log requests disabled in release.")
            #endif
        }
        get {
            #if DEBUG
            return AGSRequestConfiguration.global().debugLogRequests
            #else
            print("Debug log requests disabled in release.")
            return false
            #endif
        }
    }
}
