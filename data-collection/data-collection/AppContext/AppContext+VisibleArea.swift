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

extension AppContext {
    
    static let visibleAreaDefaultsKey = "VisibleAreaDefaultsKey.\(AppConfiguration.webMapItemID)"

    static var sharedVisibleArea: AGSViewpoint? {
        set {
            if newValue?.targetGeometry != nil { storedSharedVisibleArea = newValue }
        }
        get {
            return storedSharedVisibleArea
        }
    }
    
    private static var storedSharedVisibleArea: AGSViewpoint? = AGSViewpoint.retrieveFromUserDefaults(withKey: visibleAreaDefaultsKey) {
        didSet {
            if let visibleArea = storedSharedVisibleArea {
                visibleArea.storeInUserDefaults(withKey: visibleAreaDefaultsKey)
            }
            else {
                UserDefaults.standard.set(nil, forKey: visibleAreaDefaultsKey)
            }
        }
    }
}
