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

class PopupAttributesManager: Collection {
    
    // MARK: Collection protocol
    
    typealias Index = Int
    
    typealias Element = AnyObject
    
    var startIndex: Index {
        return 0
    }
    
    var endIndex: Index {
        return popupManager.displayFields.count + manyToOneRecords.count
    }
    
    subscript(position: Index) -> Element {
        return popupManager
    }
    
    func index(after i: Index) -> Index {
        return i + 1
    }
    
    // MARK: Properties Declaration
    
    var popupManager: AGSPopupManager
    
    var manyToOneRecords = [ManyToOneRelatedRecordsManager]()
    
    init(popupManager: AGSPopupManager) {
        self.popupManager = popupManager
    }
    
    func append(relatedRecords records: [ManyToOneRelatedRecordsManager]) {
        for record in records {
            append(relatedRecord: record)
        }
    }
    
    func append(relatedRecord record: ManyToOneRelatedRecordsManager) {
        
        guard record.loadStatus == .loaded, let relationshipInfo = record.relationshipInfo, relationshipInfo.isManyToOne else {
            return
        }
        
        manyToOneRecords.append(record)
    }
}
