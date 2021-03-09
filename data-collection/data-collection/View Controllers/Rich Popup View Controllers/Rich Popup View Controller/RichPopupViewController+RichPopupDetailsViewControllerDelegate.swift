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
        relationship.queryAndSortAllRelatedPopups { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let popups):
                // Cache the results.
                EphemeralCache.shared.setObject(
                    (popups, relationship.relatedPopup),
                    forKey: "RichPopupSelectRelatedRecord.EphemeralCacheKey"
                )
                // Segue to view controller that allows for a new related record to be selected.
                self.performSegue(withIdentifier: "RichPopupSelectRelatedRecord", sender: self)
                // Re-enabled user interaction.
                self.enableUserInteraction()
            case .failure(let error):
                // Show error
                self.showError(error)
            }
        }
    }
    
    func detailsViewController(_ detailsViewController: RichPopupDetailsViewController, selectedViewRelatedPopup manager: RichPopupManager) {
        
        // There is no segue to self, therefore we must instantiate a `RichPopupViewController` to display the related pop-up.
        let controller = storyboard?.instantiateViewController(withIdentifier: "RichPopupViewController") as? RichPopupViewController
        
        assert(controller != nil, "A configuration to this view controller's storyboard has changed. Please fix.")
        
        controller!.popupManager = manager
        
        // We only want to traverse down 1 layer at most.
        // Toggle this value to `true` for endless depth record traversal.
        controller!.shouldLoadRichPopupRelatedRecords = false
        
        // Pushes and shows the new view controller onto the navigation stack.
        show(controller!, sender: self)
    }
    
    func detailsViewController(_ detailsViewController: RichPopupDetailsViewController, selectedAddNewOneToManyRelatedRecordForRelationship relationship: OneToManyRelationship) {
        
        assert(!popupManager.isEditing, "Cannot add a one-to-many related record during an editing session.")
        
        let newPopupManager: RichPopupManager
        do {
            newPopupManager = try popupManager.buildRichPopupManagerForNewOneToManyRecord(for: relationship)
        }
        catch {
            showError(error)
            return
        }
        
        let richPopupViewController = storyboard?.instantiateViewController(withIdentifier: "RichPopupViewController") as? RichPopupViewController
        
        assert(richPopupViewController != nil, "A configuration to this view controller's storyboard has changed. Please fix.")
        
        if let richPopupViewController = richPopupViewController {
            
            richPopupViewController.popupManager = newPopupManager
            richPopupViewController.shouldLoadRichPopupRelatedRecords = false
            richPopupViewController.setEditing(true, animated: false)
            
            show(richPopupViewController, sender: self)
        }
    }
}
