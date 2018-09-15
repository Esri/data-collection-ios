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
    
    var visibleAreaDefaultsKey: String { return "VisibleAreaDefaultsKey.\(AppConfiguration.webMapItemID)" }
    
    var sharedVisibleArea: AGSViewpoint? {
        set {
            guard newValue?.targetGeometry != nil else {
                UserDefaults.standard.set(nil, forKey: visibleAreaDefaultsKey)
                return
            }
            
            if let visibleArea = newValue {
                visibleArea.storeInUserDefaults(withKey: visibleAreaDefaultsKey)
            }
            else {
                UserDefaults.standard.set(nil, forKey: visibleAreaDefaultsKey)
            }
        }
        get {
            return AGSViewpoint.retrieveFromUserDefaults(withKey: visibleAreaDefaultsKey)
        }
    }
}
