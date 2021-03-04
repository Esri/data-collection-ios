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

extension RichPopupDetailsViewController /* UITableViewDelegate */ {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if popupManager.indexPathWithinAttributes(indexPath) {
            
            assert(isEditing, "Attribute rows should only be selectable during an editing session.")

            // The user missed tapping the first responder UI element, let's ensure that UI element is selected, regardless.
            if let cell = tableView.cellForRow(at: indexPath) as? PopupAttributeCell {
                cell.firstResponder?.becomeFirstResponder()
            }
        }
        else {
            
            // Related record cells do not have a current responder, dismiss the keyboard.
            resignFirstResponder()
            
            if popupManager.indexPathWithinManyToOne(indexPath) {
                
                if isEditing {
                    
                    let manyToOneRelationship = popupManager.relationship(forIndexPath: indexPath) as? ManyToOneRelationship
                    assert(manyToOneRelationship != nil, "There should always be a relationship returned, something is wrong with the popup manager.")
                    
                    // Offer the ability to update the many to one record.
                    let relationship = manyToOneRelationship!
                    delegate?.detailsViewController(self, selectedEditManyToOneRelationship: relationship)
                }
                else {
                    let newPopupManager: RichPopupManager
                    do {
                        newPopupManager = try popupManager.buildRichPopupManagerForExistingRecord(at: indexPath)
                    }
                    catch {
                        self.showError(error)
                        return
                    }
                    
                    delegate?.detailsViewController(self, selectedViewRelatedPopup: newPopupManager)
                }
            }
            else{
                
                assert(!isEditing, "One To Many rows should not be visible in an editing session.")

                if popupManager.indexPathIsAddOneToMany(indexPath) {
                    
                    let oneToManyRelationship = popupManager.relationship(forIndexPath: indexPath) as? OneToManyRelationship
                    assert(oneToManyRelationship != nil, "There should always be a relationship returned, something is wrong with the popup manager.")
                    
                    let relationship = oneToManyRelationship!
                    delegate?.detailsViewController(self, selectedAddNewOneToManyRelatedRecordForRelationship: relationship)
                }
                else if popupManager.indexPathWithinOneToMany(indexPath) {
                    
                    let newPopupManager: RichPopupManager
                    do {
                        newPopupManager = try popupManager.buildRichPopupManagerForExistingRecord(at: indexPath)
                    }
                    catch {
                        self.showError(error)
                        return
                    }
                    
                    delegate?.detailsViewController(self, selectedViewRelatedPopup: newPopupManager)
                }
                else {
                    assertionFailure("Provided an index path that is unaccounted for.")
                }
            }
        }
    }
}
