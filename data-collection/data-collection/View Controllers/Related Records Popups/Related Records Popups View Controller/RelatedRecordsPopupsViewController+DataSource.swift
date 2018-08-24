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

extension RelatedRecordsPopupsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        var nSections = 1
        nSections += recordsManager.manyToOne.count
        
        if let feature = popup.geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable, featureTable.canDelete(feature) {
            nSections += 1
        }
        
        return nSections
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        guard section > 0 else {
            return nil
        }
        
        // Section Header for One To Many records
        let offset = section - 1
        
        if recordsManager.oneToMany.count > offset {
            return recordsManager.oneToMany[offset].name
        }
        
        return nil
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if recordsManager.indexPathWithinAttributes(indexPath) {

            let field = recordsManager.attributeField(forIndexPath: indexPath)!
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
            cell.updateCellContent()
            
            return cell as! UITableViewCell
        }
        else if recordsManager.indexPathWithinManyToOne(indexPath) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            let manager = recordsManager.relatedRecordManager(forIndexPath: indexPath) as! ManyToOneManager
            cell.table = manager.relatedTable
            cell.popup = manager.relatedPopup
            cell.relationshipInfo = manager.relationshipInfo
            cell.maxAttributes = RelatedRecordsPreferences.manyToOneCellAttributeCount
            cell.editingPopup = recordsManager.isEditing
            cell.updateCellContent()
            
            return cell
        }
        else if recordsManager.indexPathWithinOneToMany(indexPath) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            let manager = recordsManager.relatedRecordManager(forIndexPath: indexPath) as! OneToManyManager
            cell.table = manager.relatedTable
            cell.popup = manager.popup(forIndexPath: indexPath)
            cell.relationshipInfo = manager.relationshipInfo
            cell.maxAttributes = RelatedRecordsPreferences.oneToManyCellAttributeCount
            cell.editingPopup = recordsManager.isEditing
            cell.updateCellContent()
            
            return cell
        }
        else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.deletePopupCell, for: indexPath) as! DeleteRecordCell
            cell.configure(forPopup: popup)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            let nFields = recordsManager.isEditing ? recordsManager.editableDisplayFields.count : recordsManager.displayFields.count
            return nFields + recordsManager.manyToOne.count
        }
        else if recordsManager.oneToMany.count > section - 1 {
            let index = section - 1
            var nRows = recordsManager.oneToMany[index].relatedPopups.count
            
            if let table = recordsManager.oneToMany[index].relatedTable, table.canAddFeature {
                nRows += 1
            }
            
            return nRows
        }
        else {
            return 1
        }
    }
}

