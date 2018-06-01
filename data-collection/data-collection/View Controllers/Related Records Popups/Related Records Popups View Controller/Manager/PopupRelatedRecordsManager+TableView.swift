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

extension PopupRelatedRecordsManager {
    
    func indexPathWithinAttributes(_ indexPath: IndexPath) -> Bool {
        
        guard indexPath.section == 0 else {
            return false
        }
        
        let nFields = isEditing ? editableDisplayFields.count : displayFields.count
        
        return indexPath.row < nFields
    }
    
    func numberOfSections() -> Int {
        return 1 + manyToOne.count
    }
    
    func numberOfRows(inSection section: Int) -> Int {
        
        if section == 0 {
            let nFields = isEditing ? editableDisplayFields.count : displayFields.count
            return nFields + manyToOne.count
        }
        else {
            let idx = section - 1
            guard oneToMany.count > idx else {
                return 0
            }
            return oneToMany[idx].relatedPopups.count
        }
    }
    
    func maxAttributes(forSection section: Int) -> Int {
        // TODO make AppConfigurable
        return section == 0 ? 2 : 3
    }
    
    func header(forSection section: Int) -> String? {
        
        guard section > 0 else {
            return nil
        }
        
        let offset = section - 1
        
        return oneToMany[offset].name
    }
    
    func field(forIndexPath indexPath: IndexPath) -> AGSPopupField? {
        
        guard indexPath.section == 0 else {
            return nil
        }
        
        let fields = isEditing ? editableDisplayFields : displayFields
        
        guard indexPath.row < fields.count else {
            return nil
        }
        
        return fields[indexPath.row]
    }
    
    func popup(forIndexPath indexPath: IndexPath) -> AGSPopup? {
        
        // Many To One
        if indexPath.section == 0 {
            let offset = isEditing ? editableDisplayFields.count : displayFields.count
            let idx = indexPath.row - offset
            let manager = manyToOne[idx]
            return manager.relatedPopup
        }
            
        // One To Many
        else {
            let offset = 1
            let idx = indexPath.section - offset
            let manager = oneToMany[idx]
            guard manager.relatedPopups.count > indexPath.row else {
                return nil
            }
            return manager.relatedPopups[indexPath.row]
        }
    }
}
