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

extension RichPopupViewController {
    
    // MARK: Start Session
    
    func beginEditingSession() {
        
        do {
            try self.startEditingPopup()
        }
        catch {
            self.present(simpleAlertMessage: error.localizedDescription)
        }
    }
    
    private func startEditingPopup() throws {
        
        // Popup manager must not be in an editing session already.
        guard !self.popupManager.isEditing else {
            throw InvalidOperationError
        }
        
        // Editing must be enabled.
        guard self.popupManager.shouldAllowEdit, self.popupManager.startEditing() else {
            throw RichPopupManagerError.editingNotPermitted
        }
    }
    
    // MARK: Cancel Session
    
    func cancelEditingSession(_ completion: ((_ shouldDismiss: Bool) -> Void)? = nil) {
        
        let action: ((UIAlertAction) -> Void)
        
        // If the pop-up is already a member, we want to cancel editing of the pop-up and not dismiss the view controller.
        if popup.isFeatureAddedToTable {
            
            action = { [weak self] (_) in
                
                guard let self = self else { return }
                
                self.popupManager.cancelEditing()
                
                completion?(false) // shouldDismiss is passed false
            }
        }
        // If the pop-up is not a member, we can discard the pop-up altogether and dismiss the view controller.
        else {
            action = { (_) in
                completion?(true) // shouldDismiss is passed true
            }
        }
        present(confirmationAlertMessage: "Discard changes?", confirmationTitle: "Discard", confirmationAction: action)
    }
    
    // MARK: Finish Session
    
    func finishEditingSession(_ completion: ((_ success: Bool) -> Void)? = nil) {
        
        // 1. Finish editing pop-up.
        finishEditingPopup { [weak self] (error) in
            
            guard let self = self else { return }
            
            if let error = error {
                self.present(simpleAlertMessage: error.localizedDescription)
                completion?(false)
                return
            }
            
            SVProgressHUD.show(withStatus: "Saving \(self.popup.recordType.rawValue.capitalized)...")
            
            // 2. Update parent pop-up
            self.updateParentPopup { [weak self] (error) in
                
                guard let self = self else { SVProgressHUD.dismiss(); return }
                
                if let error = error {
                    SVProgressHUD.dismiss()
                    self.present(simpleAlertMessage: error.localizedDescription)
                    completion?(false)
                    return
                }
                
                // 3. Persit changes to table.
                self.persistEditsToTable { [weak self] (error) in
                    
                    SVProgressHUD.dismiss()

                    guard let self = self else { return }
                    
                    if let error = error {
                        self.present(simpleAlertMessage: error.localizedDescription)
                        completion?(false)
                        return
                    }
                    
                    completion?(true)
                }
            }
        }
    }
    
    private func finishEditingPopup(_ completion: @escaping (_ error: Error?) -> Void) {
        
        // Popup manager must not be in an editing session already.
        guard self.popupManager.isEditing else {
            completion(InvalidOperationError)
            return
        }
        
        // Ensure the popup validates.
        let invalids = self.popupManager.validatePopup()
        
        // Before saving, check that the pop-up and related records are valid.
        guard invalids.isEmpty else {
            completion(RichPopupManagerError.invalidPopup(invalids))
            return
        }
        
        // Finally, finish editing the pop-up.
        self.popupManager.finishEditing { (error) in
            completion(error)
        }
    }
    
    private func updateParentPopup(_ completion: @escaping (_ error: Error?) -> Void) {
        
        // We can complete early with no error if there is no parent pop-up.
        guard let parentPopupManager = parentPopupManager else {
            completion(nil)
            return
        }
        
        // Parent pop-up relationships must be loaded to make edits.
        guard parentPopup?.relationships?.loadStatus == .loaded else {
            
            let error = parentPopup?.relationships?.loadError ?? UnknownError
            completion(error)
            
            return
        }
        
        do {
            try parentPopupManager.update(popup)
        }
        catch {
            completion(error)
            return
        }
        
        completion(nil)
    }
    
    private func persistEditsToTable(_ completion: @escaping (_ error: Error?) -> Void) {
        
        guard let feature = self.popup.geoElement as? AGSArcGISFeature else {
            completion(FeatureTableError.invalidFeature)
            return
        }
        
        guard let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
            completion(FeatureTableError.invalidFeatureTable)
            return
        }

        featureTable.performEdit(feature: feature, completion: { [weak self] (error) in
            
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            
            self.checkIfShouldPerformCustomBehavior() { completion(nil) }
        })
    }
    
    // MARK: Delete Feature

    // Confirms with the user their intention to delete a record and performs the delete, if they confirm.
    func deletePopupAndDismissViewController() {
        
        present(confirmationAlertMessage: "Are you sure you want to delete the \(popup.recordType.rawValue)?", confirmationTitle: "Delete", confirmationAction: { [weak self] (_) in
            
            guard let self = self else { return }
            
            SVProgressHUD.show(withStatus: "Deleting \(self.popup.recordType.rawValue).")
            
            self.delete(popup: self.popup, parentPopupManager: self.parentPopupManager) { (success) in
                
                SVProgressHUD.dismiss()
                
                if !success {
                    self.present(simpleAlertMessage: "Couldn't delete \(self.popup.recordType.rawValue).")
                }
                
                self.popDismiss()
            }
            
            }, animated: true, completion: nil)
    }
    
    // In order to delete a child record, an editing session of the pop-up must be closed.
    // If editing, this function confirms with the user their intention to save the currently active editing session before deleting the child pop-up.
    func closeEditingSessionAndDelete(childPopup: AGSPopup) {
        
        let deletePopup: (AGSPopup) -> Void = { childPopup in
            
            SVProgressHUD.show(withStatus: "Deleting child \(childPopup.recordType.rawValue)")
            
            self.delete(popup: childPopup, parentPopupManager: self.popupManager) { (success) in
                
                SVProgressHUD.dismiss()
                
                self.adjustViewControllerForEditingState()
                
                if !success {
                    self.present(simpleAlertMessage: "Could not delete child \(childPopup.recordType.rawValue)")
                }
            }
        }
        
        if popupManager.isEditing {
            
            // Save the pop-up first.
            promptUserToSaveAndFinishEditingSession { [weak self] (shouldProceed: Bool) in
                
                guard let self = self else { return }
                
                guard shouldProceed else {
                    self.present(simpleAlertMessage: "Could not edit this \(self.popup.recordType.rawValue).")
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
            
            guard let rrvc = self.storyboard?.instantiateViewController(withIdentifier: "RichPopupViewController") as? RichPopupViewController else {
                self.present(simpleAlertMessage: "An unknown error occurred!")
                return
            }
            
            rrvc.popup = RichPopup(popup: childPopup)
            rrvc.parentPopup = self.popup
            rrvc.shouldBeginEditPopupUponLoad = true
            
            self.show(rrvc, sender: self)
        }
        
        if popupManager.isEditing {
            
            // save first
            promptUserToSaveAndFinishEditingSession { [weak self] (shouldProceed: Bool) in
                
                guard let self = self else { return }
                
                guard shouldProceed else {
                    
                    self.present(simpleAlertMessage: "Could not edit this \(self.popup.recordType.rawValue).")
                    return
                }
                
                beginEditing(childPopup)
            }
        }
        else {
            beginEditing(childPopup)
        }
    }
    
    // Presents a confirmation message alerting the user they must finish or cancel the pop-up editing session before proceeding.
    private func promptUserToSaveAndFinishEditingSession(_ completion: @escaping (_ shouldProceed: Bool) -> Void) {
        
        present(confirmationAlertMessage: "You must save first.", confirmationTitle: "Save", confirmationAction: { [weak self] (_) in
            
            guard let self = self else { return }
            
            self.finishEditingSession(completion)
        })
    }
    
    // Unrelates, if needed, and deletes a record from it's table.
    private func delete(popup: AGSPopup, parentPopupManager: RichPopupManager?, completion: @escaping (Bool) -> Void) {
        
        guard
            let feature = popup.geoElement as? AGSArcGISFeature,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
            featureTable.canDelete(feature) else {
                
            completion(false)
            return
        }
        
        // If the record is in a relationship, unrelate the two.
        if let parentManager = parentPopupManager {
            
            do {
                try parentManager.remove(popup)
            }
            catch {
                print("[Error: Delete Popup]", error.localizedDescription)
                completion(false)
                return
            }
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
}
