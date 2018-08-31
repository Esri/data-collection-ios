//// Copyright 2018 Esri
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

extension Bundle {
    
    private static let agsBundle = AGSBundle()
    
    private static var sdkBundleVersion: String {
        return (agsBundle?.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
    }
    
    private static var sdkVersion: String {
        return (agsBundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
    }
    
    static var ArcGISSDKVersionString: String {
        return "ArcGIS SDK \(sdkVersion) (\(sdkBundleVersion))"
    }
}

extension Bundle {
    
    private static var appDisplayName: String {
        return (main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "?"
    }
    
    private static var appVersion: String {
        return (main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
    }
    
    private static var appBundleVersion: String {
        return (main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
    }
    
    static var AppNameVersionString: String {
        return "\(appDisplayName) \(appVersion) (\(appBundleVersion))"
    }
}
