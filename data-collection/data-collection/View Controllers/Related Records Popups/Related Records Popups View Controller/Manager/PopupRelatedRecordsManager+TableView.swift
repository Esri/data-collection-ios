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

class PopupRelatedRecordsTableManager {
    
    var recordsManager: PopupRelatedRecordsManager
    
    init(withRecordsManager: PopupRelatedRecordsManager) {
        self.recordsManager = withRecordsManager
    }
    
    func field(forIndexPath indexPath: IndexPath) -> AGSPopupField? {
        
        guard indexPath.section == 0 else {
            return nil
        }
        
        let fields = recordsManager.isEditing ? recordsManager.editableDisplayFields : recordsManager.displayFields
        
        guard indexPath.row < fields.count else {
            return nil
        }
        
        return fields[indexPath.row]
    }
    
    func popup(forIndexPath indexPath: IndexPath) -> AGSPopup? {
        
        // Many To One
        if indexPath.section == 0 {
            let offset = recordsManager.isEditing ? recordsManager.editableDisplayFields.count : recordsManager.displayFields.count
            let idx = indexPath.row - offset
            let manager = recordsManager.manyToOne[idx]
            return manager.relatedPopup
        }
            
        // One To Many
        else {
            let offset = 1
            let idx = indexPath.section - offset
            let manager = recordsManager.oneToMany[idx]
            guard manager.relatedPopups.count > indexPath.row else {
                return nil
            }
            return manager.relatedPopups[indexPath.row]
        }
    }
}
