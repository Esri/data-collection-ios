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
import UIKit
import ArcGIS

extension RelatedRecordsPopupsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return oneToManyRecords.count + 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
            return nil
        }
        else {
            return oneToManyRecords[section-1].name
        }
    }
    
    // TODO Will remove cell
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Section 0
        if indexPathWithinAttributes(indexPath) {
            
            let field: AGSPopupField!
            
            if popupManager.isEditing {
                field = popupManager.editableDisplayFields[indexPath.row]
            }
            else {
                field = popupManager.displayFields[indexPath.row]
            }
            
            let fieldType = popupManager.fieldType(for: field)
            
            let cell: PopupFieldCellProtocol!
            
            if let _ = popupManager.domain(for: field) as? AGSCodedValueDomain {
                cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.codedValueCell, for: indexPath) as! PopupCodedValueCell
            }
            else {
                switch fieldType {
                case .int16, .int32, .float, .double:
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupNumberCell, for: indexPath) as! PopupNumberCell
                case .text:
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupTextCell, for: indexPath) as! PopupStringCell
                case .date:
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupDateCell, for: indexPath) as! PopupDateCell
                case .GUID, .OID, .globalID:
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupIDCell, for: indexPath) as! PopupIDCell
                default:
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupReadonlyCell, for: indexPath) as! PopupReadonlyFieldCell
                }
            }


            cell.popupManager = popupManager
            cell.field = field
            
            cell.updateCell()
            
            return cell as! UITableViewCell
        }
        else if indexPath.section == 0 {
            // M:1 Related Records
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            let recordIndex = indexPath.row - popupManager.displayFields.count
            let record = manyToOneRecords[recordIndex]
            let popup = record.popups.first
            cell.popup = popup
            cell.maxAttributes = 2
            return cell
        }
        // Section 1..n
        else {
            // 1:M Related Records
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            let record = oneToManyRecords[indexPath.section-1]
            let popup = record.popups[indexPath.row]
            cell.popup = popup
            cell.maxAttributes = 3
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
//        if indexPath.section > 0 {
//            guard let relatedRecordCell = cell as? RelatedRecordCell else {
//                return
//            }
//            // TODO CLEAN CELL?
//            relatedRecordCell.popup = nil
//        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if popupManager.isEditing {
                return popupManager.editableDisplayFields.count + manyToOneRecords.count
            }
            else {
                return popupManager.displayFields.count + manyToOneRecords.count
            }
        }
        else {
            let relationship = oneToManyRecords[section-1]
            return relationship.popups.count
        }
    }
}

