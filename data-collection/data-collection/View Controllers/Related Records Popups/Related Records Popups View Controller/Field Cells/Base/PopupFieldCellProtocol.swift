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

import ArcGIS
import UIKit

protocol PopupFieldCellProtocol {
    
    var field: AGSPopupField? { get set }
    var popupManager: PopupRelatedRecordsManager? { get set }
    
    func refreshCell()
}

extension PopupFieldCellProtocol {
    
    var isValueEditable: Bool {
        
        guard let field = field, let popupManager = popupManager else {
            return false
        }
        
        return popupManager.editableDisplayFields.contains(field)
    }
    
    var fieldType: AGSFieldType? {
        
        guard let field = field, let popupManager = popupManager else {
            return nil
        }
        
        return popupManager.fieldType(for: field)
    }
    
    // TODO support
    var domain: AGSDomain? {
        
        guard let field = field, let popupManager = popupManager else {
            return nil
        }
        
        return popupManager.domain(for: field)
    }
}

struct ReuseIdentifiers {

    static let popupNumberCell = "PopupNumberCellReuseIdentifier"
    static let popupShortTextCell = "PopupShortTextCellReuseIdentifier"
    static let popupLongTextCell = "PopupLongTextCellReuseIdentifier"
    static let popupDateCell = "PopupDateCellReuseIdentifier"
    static let popupIDCell = "PopupIDCellReuseIdentifier"
    static let popupReadonlyCell = "PopupReadonlyCellReuseIdentifier"
    static let codedValueCell = "PopupCodedValueCellReuseIdentifier"
    static let relatedRecordCell = "RelatedRecordCellReuseID"
    static let deletePopupCell = "DeleteFeatureCell"
}
