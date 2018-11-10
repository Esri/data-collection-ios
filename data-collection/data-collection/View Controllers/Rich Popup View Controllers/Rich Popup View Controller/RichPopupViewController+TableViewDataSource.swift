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

struct RelatedRecordsPreferences {
    
    static let manyToOneCellAttributeCount = 2
    static let oneToManyCellAttributeCount = 3
}


extension RichPopupViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        var n = 1

        // The number of sections is defined as (n) many-to-one related tables + 1.
        n += popup.relationships?.manyToOne.count ?? 0
        
        if let feature = popup.geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable, featureTable.canDelete(feature) {
            n += 1
        }
        
        return n
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        guard section > 0, let managers = popup.relationships?.oneToMany else {
            return nil
        }
        
        // Section Header for One To Many records
        let offset = section - 1
        
        if managers.count > offset {
            return popup.relationships?.oneToMany[offset].name ?? nil
        }
        
        return nil
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if popupManager.indexPathWithinAttributes(indexPath) {

            let field = popupManager.attributeField(forIndexPath: indexPath)!
            let fieldType = popupManager.fieldType(for: field)
            
            let cell: PopupFieldCellProtocol!
            
            if popupManager.domain(for: field) is AGSCodedValueDomain {
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
            
            cell.popupManager = popupManager
            cell.field = field
            cell.updateCellContent()
            
            return cell as! UITableViewCell
        }
        else if popupManager.indexPathWithinManyToOne(indexPath) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            let relationship = popupManager.relationship(forIndexPath: indexPath) as! ManyToOneRelationship
            cell.table = relationship.relatedTable
            cell.popup = relationship.relatedPopup
            cell.relationshipInfo = relationship.relationshipInfo
            cell.maxAttributes = RelatedRecordsPreferences.manyToOneCellAttributeCount
            cell.editingPopup = popupManager.isEditing
            cell.updateCellContent()
            
            return cell
        }
        else if popupManager.indexPathWithinOneToMany(indexPath) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            let relationship = popupManager.relationship(forIndexPath: indexPath) as! OneToManyRelationship
            cell.table = relationship.relatedTable
            cell.popup = relationship.popup(forIndexPath: indexPath)
            cell.relationshipInfo = relationship.relationshipInfo
            cell.maxAttributes = RelatedRecordsPreferences.oneToManyCellAttributeCount
            cell.editingPopup = popupManager.isEditing
            cell.updateCellContent()
            
            return cell
        }
        else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.deletePopupCell, for: indexPath) as! DeleteRecordCell
            cell.configure(withRecordTypeName: popup.recordType.rawValue)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let fieldCell = cell as? PopupFieldCellProtocol {
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
            
            var nFields = popupManager.isEditing ? popupManager.editableDisplayFields.count : popupManager.displayFields.count
            
            if let managers = popup.relationships?.manyToOne {
                nFields += managers.count
            }
            
            return nFields
        }
        else if let managers = popup.relationships?.oneToMany, managers.count > section - 1 {
            
            let index = section - 1
            var nRows = managers[index].relatedPopups.count
            
            if let table = managers[index].relatedTable, table.canAddFeature {
                nRows += 1
            }
            
            return nRows
        }
        else {
            return 1
        }
    }
}

