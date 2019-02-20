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

extension RichPopupViewController: RichPopupDetailsViewControllerDelegate {
    
    func detailsViewController(_ detailsViewController: RichPopupDetailsViewController, selectedEditManyToOneRelationship relationship: ManyToOneRelationship) {
        
        // Disable user interaction of the view controller (disallowing 'Done' or 'Cancel' to be tapped repeatedly)
        // and display status message to the user.
        disableUserInteraction(status: "Loading Records")
        
        // Query all related popup's for the selected many-to-one relationship
        relationship.queryAndSortAllRelatedPopups { [weak self] (error, popups) in
            
            guard let self = self else { return }
            
            if let error = error {
                self.present(simpleAlertMessage: error.localizedDescription)
                return
            }
            
            guard let popups = popups else {
                self.present(simpleAlertMessage: NSError.unknown.localizedDescription)
                return
            }
            
            // Cache the results.
            EphemeralCache.set(object: (popups, relationship.relatedPopup), forKey: "RichPopupSelectRelatedRecord.EphemeralCacheKey")
            
            // Segue to view controller that allows for a new related record to be selected.
            self.performSegue(withIdentifier: "RichPopupSelectRelatedRecord", sender: self)
            
            // Re-enabled user interaction.
            self.enableUserInteraction()
        }
    }
    
    func detailsViewController(_ detailsViewController: RichPopupDetailsViewController, selectedViewRelatedPopup manager: RichPopupManager) {
        
        // There is no segue to self, therefore we must instantiate a `RichPopupViewController` to display the related pop-up.
        let richPopupViewController = storyboard?.instantiateViewController(withIdentifier: "RichPopupViewController") as? RichPopupViewController
        
        assert(richPopupViewController != nil, "A configuration to this view controller's storyboard has changed. Please fix.")
        
        if let richPopupViewController = richPopupViewController {
            
            richPopupViewController.popupManager = manager
            
            // We only want to traverse down 1 layer at most.
            // Toggle this value to `true` for endless depth record traversal.
            richPopupViewController.shouldLoadRichPopupRelatedRecords = false
            
            // Pushes and shows the new view controller onto the navigation stack.
            show(richPopupViewController, sender: self)
        }
        else {
            
            present(simpleAlertMessage: "Unable to show record.")
        }
    }
    
    func detailsViewController(_ detailsViewController: RichPopupDetailsViewController, selectedAddNewOneToManyRelatedRecordForRelationship relationship: OneToManyRelationship) {
        
        // Use this local scope function to build a view controller to display and edit a new one-to-many related record.
        func buildChildViewController() {
            do {
                if let newPopupManager = try popupManager.buildRichPopupManagerForNewOneToManyRecord(for: relationship) {
                    
                    let richPopupViewController = storyboard?.instantiateViewController(withIdentifier: "RichPopupViewController") as? RichPopupViewController
                    
                    assert(richPopupViewController != nil, "A configuration to this view controller's storyboard has changed. Please fix.")
                    
                    if let richPopupViewController = richPopupViewController {
                        
                        richPopupViewController.popupManager = newPopupManager
                        richPopupViewController.shouldLoadRichPopupRelatedRecords = false
                        richPopupViewController.setEditing(true, animated: false)
                        
                        show(richPopupViewController, sender: self)
                    }
                }
                else {
                    self.present(simpleAlertMessage: NSError.unknown.localizedDescription)
                }
            }
            catch {
                self.present(simpleAlertMessage: error.localizedDescription)
            }
        }
        
        if popupManager.isEditing {
            
            // Prompt the user to finish editing before adding a new related record.
            self.present(confirmationAlertMessage: "You must finish editing this record before adding a new one.",
                         confirmationTitle: "Save",
                         isDestructive: false,
                         confirmationAction: { [weak self] (_) in
                            
                            guard let self = self else { return }
                            
                            self.finishEditingSession { [weak self] (error) in
                                
                                guard let self = self else { return }
                                
                                if let error = error {
                                    self.present(simpleAlertMessage: "Could not save the record. \(error.localizedDescription)")
                                }
                                else {
                                    buildChildViewController()
                                }                                
                            }
            })
        }
        else {
            // If not editing, jump straight to building the view controller.
            buildChildViewController()
        }
    }
}
