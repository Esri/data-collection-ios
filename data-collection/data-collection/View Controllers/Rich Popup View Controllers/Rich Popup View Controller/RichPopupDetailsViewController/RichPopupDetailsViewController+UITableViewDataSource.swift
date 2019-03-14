//// Copyright 2019 Esri
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

extension RichPopupDetailsViewController /* UITableViewDataSource */ {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        let attributesAndManyToOneSection = 1
        
        if isEditing {
            return attributesAndManyToOneSection
        }
        else {
            
            guard popupManager.richPopup.relationships?.loadStatus == .loaded else {
                return attributesAndManyToOneSection
            }
            
            return attributesAndManyToOneSection + (popupManager.richPopup.relationships?.oneToMany.count ?? 0)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            
            var nFields: Int
            
            if popupManager.isEditing {
                nFields = popupManager.editableDisplayFields.count
            }
            else {
                nFields = popupManager.displayFields.count
            }
            
            if popupManager.richPopup.relationships?.loadStatus == .loaded, let managers = popupManager.richPopup.relationships?.manyToOne {
                nFields += managers.count
            }
            
            return nFields
        }
        else {
            
            guard !isEditing else {
                assertionFailure("There should only be one section when editing.")
                return 0
            }
            
            if let managers = popupManager.richPopup.relationships?.oneToMany, managers.count + 1 > section {
                
                let index = section - 1
                var nRows = managers[index].relatedPopups.count
                
                if managers[index].canAddRecord {
                    nRows += 1
                }
                
                return nRows
            }
            else {
                assertionFailure("There should never be a section number higher than 1 + n(one-to-many) relationships.")
                return 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if popupManager.indexPathWithinAttributes(indexPath) {
            
            let field = popupManager.attributeField(forIndexPath: indexPath)!
            let fieldType = popupManager.fieldType(for: field)
            
            let cell: PopupAttributeCell!
            
            // If the field is contextualized by a domain, we'll allow the domain to inform editing values of the field.
            if let domain = popupManager.domain(for: field) as? AGSCodedValueDomain {
                // Tapping the first responder of a domain cell triggers a picker view containing all coded value domain options.
                let domainCell = tableView.dequeueReusableCell(withIdentifier: "PopupAttributeDomainCell", for: indexPath) as! PopupAttributeDomainCell
                domainCell.domain = domain
                cell = domainCell
            }
            else {
                switch (fieldType, field.stringFieldOption) {
                    
                case (.int16, _), (.int32, _), (.float, _), (.double, _):
                    let textFieldCell = tableView.dequeueReusableCell(withIdentifier: "PopupAttributeTextFieldCell", for: indexPath) as! PopupAttributeTextFieldCell
                    textFieldCell.attributeValueTextField.keyboardType = .numberPad
                    cell = textFieldCell
                    
                case (.text, .multiLine), (.text, .richText):
                    let textViewCell = tableView.dequeueReusableCell(withIdentifier: "PopupAttributeTextViewCell", for: indexPath) as! PopupAttributeTextViewCell
                    textViewCell.attributeValueTextView.keyboardType = .default
                    cell = textViewCell
                    
                case (.text, .singleLine), (.text, .unknown):
                    let textFieldCell = tableView.dequeueReusableCell(withIdentifier: "PopupAttributeTextFieldCell", for: indexPath) as! PopupAttributeTextFieldCell
                    textFieldCell.attributeValueTextField.keyboardType = .default
                    cell = textFieldCell
                    
                case (.date, _):
                    cell = tableView.dequeueReusableCell(withIdentifier: "PopupAttributeDateCell", for: indexPath) as! PopupAttributeDateCell
                    
                case (.GUID, _), (.OID, _), (.globalID, _), (.unknown, _):
                    cell = tableView.dequeueReusableCell(withIdentifier: "PopupAttributeReadonlyCell", for: indexPath) as! PopupAttributeReadonlyCell
                
                // Data Collection currently does not support field types: `.geometry`, `.raster`, `.XML` and `.blob`.
                case (.geometry, _), (.raster, _), (.XML, _), (.blob, _):
                    fallthrough
                    
                default:
                    assertionFailure("Data Collection doesn't currently support the \(String(describing: fieldType)) field type.")
                    return UITableViewCell()
                }
            }
            
            let title = field.label
            
            let formatted = popupManager.formattedValue(for: field)
            let raw = popupManager.value(for: field)
            
            cell.setTitle(title, value: (formatted, raw))
            cell.delegate = self
            
            if isEditing {
                // For editing cells, validate the cell after configuration.
                let error = popupManager.validationError(for: field)
                cell.setValidity(error)
            }
            else {
                // Passing no error restores the cell to a visibly "valid" state.
                cell.setValidity(nil)
            }
            
            return cell as! UITableViewCell
        }
        else {
            if popupManager.indexPathWithinManyToOne(indexPath) {
                
                let manyToOneCell = tableView.dequeueReusableCell(withIdentifier: "PopupRelatedRecordCell", for: indexPath) as! PopupRelatedRecordCell
                let relationship = popupManager.relationship(forIndexPath: indexPath) as! ManyToOneRelationship
                
                var attributes = [AGSPopupManager.DisplayAttribute]()
                
                if let relatedPopup = relationship.relatedPopup {
                    attributes = AGSPopupManager.generateDisplayAttributes(forPopup: relatedPopup, max: RelatedRecordsConfiguration.maxManyToOne.rawValue)
                    manyToOneCell.setAttributes(attributes)
                }
                else {
                    manyToOneCell.setMissingValueFor(tableName: relationship.name)
                }
                
                return manyToOneCell
            }
            else if popupManager.indexPathIsAddOneToMany(indexPath) {
                
                let addOneToManyCell = tableView.dequeueReusableCell(withIdentifier: "PopupNewOneToManyRecordCell", for: indexPath) as! PopupNewRelatedRecordCell
                
                if let relationship = popupManager.relationship(forIndexPath: indexPath) as? OneToManyRelationship {
                    addOneToManyCell.setTableName(relationship.name)
                }
                
                return addOneToManyCell
            }
            else if popupManager.indexPathWithinOneToMany(indexPath) {
                
                let oneToManyCell = tableView.dequeueReusableCell(withIdentifier: "PopupRelatedRecordCell", for: indexPath) as! PopupRelatedRecordCell
                
                var attributes = [AGSPopupManager.DisplayAttribute]()
                
                if let relationship = popupManager.relationship(forIndexPath: indexPath) as? OneToManyRelationship, let relatedPopup = relationship.popup(forIndexPath: indexPath) {
                    attributes = AGSPopupManager.generateDisplayAttributes(forPopup: relatedPopup, max: RelatedRecordsConfiguration.maxOneToMany.rawValue)
                }
                
                oneToManyCell.setAttributes(attributes)
                return oneToManyCell
            }
            else {
                assertionFailure("This index path is not supported.")
                return UITableViewCell()
            }
        }
    }
    
    fileprivate var activityIndicatorViewHeight: CGFloat { return 35.0 }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0, popupManager.richPopup.relationships?.loadStatus == .loading {
            return activityIndicatorViewHeight
        }
        else {
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // If the view controller is loading related records, we want to add an activity indicator view in the table view's header.
        guard section == 0, popupManager.richPopup.relationships?.loadStatus == .loading else {
            return nil
        }
        
        let container = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.width, height: activityIndicatorViewHeight))
        container.backgroundColor = .clear
        
        let activity = UIActivityIndicatorView(style: .gray)
        activity.accessibilityLabel = "Loading Related Records"
        activity.startAnimating()
        
        container.addSubview(activity)
        activity.center = container.convert(container.center, from:container.superview)
        return container
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if isEditing {
            return nil
        }
        else {
            guard section > 0 else { return nil }
            
            let offset = section - 1
            
            guard let relationships = popupManager.richPopup.relationships, relationships.oneToMany.endIndex > offset else {
                return nil
            }
            
            return relationships.oneToMany[offset].name
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        if isEditing {
            // All rows can be highlighted when editing.
            return true
        }
        else {
            // Only related record type rows are highlightable/selectable when not in an editing session.
            return !popupManager.indexPathWithinAttributes(indexPath)
        }
    }
}
