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
    
    static let itemID = "fcc7fc65bb96464c9c0986576c119a92"
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
    
    // MARK: UI Config
    
    static let config = AppConfiguration()
    
    static var relatedRecordPrefs: RelatedRecordsPreferences {
        return config.prefs
    }
    
    private var prefs = RelatedRecordsPreferences()
    
    // Colors
    static var appColors: AppColors {
        return config.colors
    }
    
    private let colors = AppColors()
    
    // Fonts
    static var appFonts: AppFonts {
        return config.fonts
    }
    
    private let fonts = AppFonts()
}

struct RelatedRecordsPreferences {
    
    let manyToOneCellAttributeCount = 2
    let oneToManyCellAttributeCount = 3
}

struct AppColors {
    
    let primary: UIColor = UIColor(red:0.66, green:0.81, blue:0.40, alpha:1.00)
    
    let offline: UIColor = .darkGray
    let offlineLight: UIColor = .gray
    let offlineDark: UIColor = .black
    
    let accent: UIColor = UIColor(red:0.93, green:0.54, blue:0.01, alpha:1.00)
    
    let tableCellTitle: UIColor = .gray
    let tableCellValue: UIColor = .black
    
    let invalid: UIColor = .red
}

struct AppFonts {
    
    let tableCellTitle: UIFont = UIFont.preferredFont(forTextStyle: .footnote)
    let tableCellValue: UIFont = UIFont.preferredFont(forTextStyle: .body)
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
            return false
            print("Debug log requests disabled in release.")
            #endif
        }
    }
}
