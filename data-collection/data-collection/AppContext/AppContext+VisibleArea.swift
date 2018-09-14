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

extension AGSViewpoint: AppUserDefaultsProtocol {
    
    func storeViewPoint() {
        
        let json = try? self.toJSON()
        AGSViewpoint.setUserDefault(json)
    }
    
    static func getDefaultViewPoint() -> AGSViewpoint? {
        
        guard let viewPointJSON = AGSViewpoint.getUserDefaultValue() else { return nil }
        let serializedJSON = try? AGSViewpoint.fromJSON(viewPointJSON)
        return serializedJSON as? AGSViewpoint
    }
    
    typealias ValueType = Any
    
    static let userDefaultsKey = "VisibleAreaDefaultsKey.\(AppConfiguration.webMapItemID)"
}

extension AppContext {
    
    static var sharedVisibleArea: AGSViewpoint? {
        set {
            if newValue?.targetGeometry != nil { storedSharedVisibleArea = newValue }
        }
        get {
            return storedSharedVisibleArea
        }
    }
    
    private static var storedSharedVisibleArea: AGSViewpoint? = AGSViewpoint.getDefaultViewPoint() {
        didSet {
            if let visibleArea = storedSharedVisibleArea {
                visibleArea.storeViewPoint()
            }
            else {
                AGSViewpoint.clearUserDefaultValue()
            }
        }
    }
}
