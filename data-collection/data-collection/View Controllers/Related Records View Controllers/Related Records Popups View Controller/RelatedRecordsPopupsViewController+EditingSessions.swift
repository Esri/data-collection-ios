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
import ArcGIS

extension RelatedRecordsPopupsViewController {
    
    // This function is called to start or end editing the pop-up, with a completion closure.
    func editPopup(_ startEditing: Bool, completion: ((_ proceed: Bool) -> Void)? = nil) {
        
        // Calls for the editing session to start, if possible.
        if startEditing {
            
            guard !recordsManager.isEditing else {
                completion?(true)
                return
            }
            
            guard recordsManager.shouldAllowEdit, recordsManager.startEditing() else {
                present(simpleAlertMessage: "Unexpected error, you couldn't edit this \(popup.recordType.rawValue).")
                completion?(false)
                return
            }
            
            adjustViewControllerForEditState()
            completion?(true)
        }
        // Finishes the editing session, if possible.
        else {
            
            guard recordsManager.isEditing else {
                completion?(true)
                return
            }
            
            let invalids = recordsManager.validatePopup()
            
            // Before saving, check that the pop-up and related records are valid.
            guard invalids.isEmpty else {
                self.present(simpleAlertMessage: "You cannot save this \(popup.recordType.rawValue). There \(invalids.count == 1 ? "is" : "are") \(invalids.count) invalid field\(invalids.count == 1 ? "" : "s").")
                completion?(false)
                return
            }
            
            // Then, finish editing the pop-up.
            recordsManager.finishEditing { [weak self] (error) in
                
                guard
                    error == nil,
                    let feature = self?.popup.geoElement as? AGSArcGISFeature,
                    let featureTable = feature.featureTable as? AGSArcGISFeatureTable
                    else {
                        print("[Error: Validating Feature]", error?.localizedDescription ?? "")
                        self?.present(simpleAlertMessage: "Could not edit \(self?.popup.recordType.rawValue ?? "popup")!")
                        self?.recordsManager.cancelEditing()
                        completion?(true)
                        return
                }
                
                SVProgressHUD.show(withStatus: "Saving \(self?.popup.recordType.rawValue.capitalized ?? "Popup")...")
                
                if let childPopup = self?.popup, let manager = self?.parentRecordsManager, let relationship = manager.popup.oneToManyRelationship(withPopup: childPopup) {
                    
                    do {
                        try manager.edit(oneToMany: childPopup, forRelationship: relationship)
                    }
                    catch {
                        SVProgressHUD.dismiss()
                        self?.present(simpleAlertMessage: "Unexpected error, you couldn't edit this \(self?.popup.recordType.rawValue ?? "popup").")
                        print("[Error: Records Manager]", error.localizedDescription)
                        return
                    }
                }
                
                // Finally, persist the changes to the feature table.
                featureTable.performEdit(feature: feature, completion: { [weak self] (error) in
                    
                    SVProgressHUD.dismiss()
                    
                    if error != nil {
                        self?.present(simpleAlertMessage: "Unexpected error, you couldn't edit this \(self?.popup.recordType.rawValue ?? "popup").")
                        print("[Error] feature table edit error", error!.localizedDescription)
                    }
                    
                    self?.adjustViewControllerForEditState()
                    
                    // If the web map in question is Trees of Portland, perform an additional custom behavior, else finish.
                    self?.checkIfShouldPerformCustomBehavior() { completion?(true) }
                })
            }
        }
    }
    
    // Presents a confirmation message alerting the user they must finish or cancel the pop-up editing session before proceeding.
    func attemptToSavePopup(_ completion: @escaping (_ shouldProceed: Bool) -> Void) {
        
        guard recordsManager.isEditing else {
            completion(true)
            return
        }
        
        present(confirmationAlertMessage: "You must save first.", confirmationTitle: "Save", confirmationAction: { [weak self] (_) in
            self?.editPopup(false, completion: completion)
        })
    }
    
    // MARK: Delete Feature
    
    // Unrelates, if needed, and deletes a record from it's table.
    private func delete(popup: AGSPopup, parentPopupManager: PopupRelatedRecordsManager?, completion: @escaping (Bool) -> Void) {
        
        // If the record is in a relationship, unrelate the two.
        if let parentManager = parentPopupManager, let relationship = parentManager.popup.oneToManyRelationship(withPopup: popup) {
            
            do {
                try parentManager.delete(oneToMany: popup, forRelationship: relationship)
            }
            catch {
                print("[Error: Delete Popup]", error.localizedDescription)
                completion(false)
                return
            }
        }
        
        guard let feature = popup.geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable, featureTable.canDelete(feature) else {
            completion(false)
            return
        }
        
        // Delete the record from the table.
        featureTable.performDelete(feature: feature) { [weak self] (error) in
            
            guard error == nil else {
                print("[Error: Feature Table Delete]", error!.localizedDescription)
                completion(false)
                return
            }
            
            self?.checkIfShouldPerformCustomBehavior { completion(true) }
        }
    }
    
    // Confirms with the user their intention to delete a record and performs the delete, if they confirm.
    func deletePopupAndDismissViewController() {
        
        present(confirmationAlertMessage: "Are you sure you want to delete \(popup.recordType.rawValue)?", confirmationTitle: "Delete", confirmationAction: { [weak self] (_) in
            
            guard let popup = self?.popup else {
                self?.present(simpleAlertMessage: "Something went wrong. Couldn't delete \(self?.popup.recordType.rawValue ?? "popup").")
                return
            }
            
            SVProgressHUD.show(withStatus: "Deleting \(self?.popup.recordType.rawValue ?? "popup").")
            
            self?.delete(popup: popup, parentPopupManager: self?.parentRecordsManager) { (success) in
                
                SVProgressHUD.dismiss()
                
                if !success {
                    self?.present(simpleAlertMessage: "Couldn't delete \(self?.popup.recordType.rawValue ?? "popup").")
                }
                
                self?.popDismiss()
            }
            
            }, animated: true, completion: nil)
    }
    
    // In order to delete a child record, an editing session of the pop-up must be closed.
    // If editing, this function confirms with the user their intention to save the currently active editing session before deleting the child pop-up.
    func closeEditingSessionAndDelete(childPopup: AGSPopup) {
        
        let deletePopup: (AGSPopup) -> Void = { childPopup in
            
            SVProgressHUD.show(withStatus: "Deleting child \(childPopup.recordType.rawValue)")
            
            self.delete(popup: childPopup, parentPopupManager: self.recordsManager) { (success) in
                
                SVProgressHUD.dismiss()
                self.tableView.reloadData()
                
                if !success {
                    self.present(simpleAlertMessage: "Could not delete child \(childPopup.recordType.rawValue)")
                }
            }
        }
        
        if recordsManager.isEditing {
            
            // Save the pop-up first.
            attemptToSavePopup { [weak self] (shouldProceed: Bool) in
                
                guard shouldProceed else {
                    self?.present(simpleAlertMessage: "Could not edit this \(self?.popup.recordType.rawValue ?? "popup").")
                    return
                }
                
                deletePopup(childPopup)
            }
        }
        else {
            deletePopup(childPopup)
        }
    }
    
    // In order to edit a child one-to-many record, an editing session of the pop-up must be closed.
    // If editing, this function confirms with the user their intention to save the currently active editing session before editing the child pop-up.
    func closeEditingSessionAndBeginEditing(childPopup: AGSPopup) {
        
        let beginEditing: (AGSPopup) -> Void = { [weak self] childPopup in
            
            guard let self = self else { return }
            
            guard let rrvc = self.storyboard?.instantiateViewController(withIdentifier: "RelatedRecordsPopupsViewController") as? RelatedRecordsPopupsViewController, let parentRecordsManager = self.recordsManager else {
                self.present(simpleAlertMessage: "An unknown error occurred!")
                return
            }
            
            rrvc.popup = childPopup
            rrvc.parentRecordsManager = parentRecordsManager
            rrvc.editPopup(true)
            
            self.show(rrvc, sender: self)
        }
        
        if recordsManager.isEditing {
            
            // save first
            attemptToSavePopup { [weak self] (shouldProceed: Bool) in
                
                guard shouldProceed else {
                    self?.present(simpleAlertMessage: "Could not edit this \(self?.popup.recordType.rawValue ?? "popup").")
                    return
                }
                
                beginEditing(childPopup)
            }
        }
        else {
            beginEditing(childPopup)
        }
    }
}
