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
    
    // TODO Will remove cell function
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let field = recordsTableManager.field(forIndexPath: indexPath) {
            
            let fieldType = recordsManager.fieldType(for: field)
            
            let cell: PopupFieldCellProtocol!
            
            if let _ = recordsManager.domain(for: field) as? AGSCodedValueDomain {
                cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.codedValueCell, for: indexPath) as! PopupCodedValueCell
            }
            else {
                switch fieldType {
                case .int16, .int32, .float, .double:
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupNumberCell, for: indexPath) as! PopupNumberCell
                case .text:
                    if field.stringFieldOption == .multiLine || field.stringFieldOption == .richText {
                        cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupLongTextCell, for: indexPath) as! PopupLongStringCell
                    }
                    else {
                        cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupShortTextCell, for: indexPath) as! PopupShortStringCell
                    }
                case .date:
                    cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupDateCell, for: indexPath) as! PopupDateCell
                case .GUID, .OID, .globalID:
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
            let popup = recordsTableManager.popup(forIndexPath: indexPath)
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            cell.popup = popup
            
            // TODO make AppConfigurable
            let maxAttributes = indexPath.section == 0 ? 2 : 3
            
            cell.maxAttributes = maxAttributes
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        // TODO clean cell?
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
            return recordsManager.oneToMany[idx].relatedPopups.count
        }
    }
}

