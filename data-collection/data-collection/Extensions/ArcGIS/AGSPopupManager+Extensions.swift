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

extension AGSPopupManager {
    
    public func nextFieldStringValue(idx: inout Int) -> String? {
        
        guard displayFields.count >= idx + 1 else {
            return nil
        }
        
        let field = displayFields[idx]
        let value = formattedValue(for: field)
        
        idx += 1
        return value
    }
    
    var table: AGSFeatureTable? {
        return (popup.geoElement as? AGSArcGISFeature)?.featureTable
    }
    
    var tableName: String? {
        return table?.tableName
    }
}
