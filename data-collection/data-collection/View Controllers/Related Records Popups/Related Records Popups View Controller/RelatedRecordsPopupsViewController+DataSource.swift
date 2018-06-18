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
        
        return 1 + recordsManager.manyToOne.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        guard section > 0 else {
            return nil
        }
        
        let offset = section - 1
        
        return recordsManager.oneToMany[offset].name
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let attributeFields = recordsManager.isEditing ? recordsManager.editableDisplayFields : recordsManager.displayFields
        
        if indexPath.section == 0, indexPath.row < attributeFields.count {
            
            let field = attributeFields[indexPath.row]
            let fieldType = recordsManager.fieldType(for: field)
            
            let cell: PopupFieldCellProtocol!
            
            if let _ = recordsManager.domain(for: field) as? AGSCodedValueDomain {
                cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.codedValueCell, for: indexPath) as! PopupCodedValueCell
            }
            else {
                switch (fieldType, field.stringFieldOption) {
                case (.int16, _), (.int32, _), (.float, _), (.double, _):
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupNumberCell, for: indexPath) as! PopupNumberCell
                case (.text, .multiLine), (.text, .richText):
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupLongTextCell, for: indexPath) as! PopupLongStringCell
                case (.text, .singleLine), (.text, .unknown):
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupShortTextCell, for: indexPath) as! PopupShortStringCell
                case (.date, _):
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupDateCell, for: indexPath) as! PopupDateCell
                case (.GUID, _), (.OID, _), (.globalID, _):
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupIDCell, for: indexPath) as! PopupIDCell
                default:
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupReadonlyCell, for: indexPath) as! PopupReadonlyFieldCell
                }
            }
            
            cell.popupManager = recordsManager
            cell.field = field
            
            cell.refreshCell()
            
            return cell as! UITableViewCell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            
            // Many To One
            if indexPath.section == 0 {
                let sectionOffset = recordsManager.isEditing ? recordsManager.editableDisplayFields.count : recordsManager.displayFields.count
                let idx = indexPath.row - sectionOffset
                let manager = recordsManager.manyToOne[idx]
                cell.table = manager.relatedTable
                cell.popup = manager.relatedPopup
                cell.relationshipInfo = manager.relationshipInfo
                cell.maxAttributes = AppConfiguration.relatedRecordPrefs.manyToOneCellAttributeCount
            }
            // One To Many
            else {
                let sectionOffset = 1
                let sectionIDX = indexPath.section - sectionOffset
                let manager = recordsManager.oneToMany[sectionIDX]
                cell.table = manager.relatedTable
                
                var rowOffset = 0
                
                if let table = manager.relatedTable, table.canAddFeature {
                    rowOffset += 1
                }
                
                let rowIDX = indexPath.row - rowOffset
                
                if indexPath.row < rowOffset {
                    cell.popup = nil
                    cell.relationshipInfo = manager.relationshipInfo
                }
                else if manager.relatedPopups.count <= rowIDX {
                    cell.popup = nil
                    cell.relationshipInfo = nil
                }
                else {
                    cell.popup = manager.relatedPopups[rowIDX]
                    cell.relationshipInfo = manager.relationshipInfo
                }
                
                cell.maxAttributes = AppConfiguration.relatedRecordPrefs.oneToManyCellAttributeCount
            }
            
            cell.editingPopup = recordsManager.isEditing
            cell.updateCellContent()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if var fieldCell = cell as? PopupFieldCellProtocol {
            fieldCell.popupManager = nil
            fieldCell.field = nil
        }
        else if let relatedRecordCell = cell as? RelatedRecordCell {
            relatedRecordCell.table = nil
            relatedRecordCell.popup = nil
            relatedRecordCell.relationshipInfo = nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            let nFields = recordsManager.isEditing ? recordsManager.editableDisplayFields.count : recordsManager.displayFields.count
            return nFields + recordsManager.manyToOne.count
        }
        else {
            let idx = section - 1

            guard recordsManager.oneToMany.count > idx else {
                return 0
            }
            
            var nRows = recordsManager.oneToMany[idx].relatedPopups.count
            
            if let table = recordsManager.oneToMany[idx].relatedTable, table.canAddFeature {
                nRows += 1
            }
            
            return nRows
        }
    }
}

