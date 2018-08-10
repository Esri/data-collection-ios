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
    
    public func labelTitle(fieldIndex: Int) -> String? {
        
        guard fieldIndex < displayFields.count else {
            return nil
        }
        
        return displayFields[fieldIndex].label
    }
    
    public func labelValue(fieldIndex: Int) -> String? {
        
        guard fieldIndex < displayFields.count else {
            return nil
        }
        
        let field = displayFields[fieldIndex]
        let value = formattedValue(for: field)
        
        return value
    }
    
    public func nextFieldStringValue(fieldIndex: inout Int) -> String? {
        
        guard fieldIndex < displayFields.count else {
            return nil
        }
        
        let value = labelValue(fieldIndex: fieldIndex)
        
        fieldIndex += 1
        return value
    }
    
    var table: AGSFeatureTable? {
        return (popup.geoElement as? AGSArcGISFeature)?.featureTable
    }
    
    var tableName: String? {
        return table?.tableName
    }
    
    var actionButtonTitle: String {
        return isEditing ? "Done" : "Edit"
    }
}
