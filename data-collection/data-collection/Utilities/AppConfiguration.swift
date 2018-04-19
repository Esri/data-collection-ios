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

typealias Config = AppConfiguration

class AppConfiguration {
    
    static let itemID = "1eabfa0e397448b487892441f86de273"
    static let basePortalDomain = "www.arcgis.com"
    static let basePortalURLString = "https://\(basePortalDomain)"
    static let basePortalURL: URL? = URL(string: basePortalURLString)
    static let portalURL: URL? = URL(string: "\(basePortalURLString)/home/item.html?id=\(itemID)")
    static let geocodeServiceURL: URL? = URL(string: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")
    static let urlScheme: String = "data-collection"
    static let urlAuthPath: String = "auth"
    static let oAuthRedirectURLString: String = "\(urlScheme)://\(urlAuthPath)"
    static let keychainIdentifier: String = "\(appBundleID).keychain"
    static let licenseKey: String = "fake_license_key"
    static let clientID: String = "AaXxKoHH3piT1fe3"
    
    static let colors = AppColors()
}

enum AppColorsTheme {
    case light
    case dark
}

struct AppColors {
    
    static var primary: UIColor = UIColor(red:0.66, green:0.81, blue:0.40, alpha:1.00)
    static var primaryLight: UIColor = { return primary.lighter }()
    static var primaryDark: UIColor = { return primary.darker }()
    
    static var offline: UIColor = .darkGray
    static var offlineLight: UIColor = .gray
    static var offlineDark: UIColor = .black
    
    static var accent: UIColor = UIColor(red:0.93, green:0.54, blue:0.01, alpha:1.00)
}
