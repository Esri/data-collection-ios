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

import UIKit
import QuickLook
import ArcGIS

class RichPopupViewController: SegmentedViewController {
    
    // MARK: Rich Popup
    
    var popupManager: RichPopupManager!

    var shouldLoadRichPopupRelatedRecords: Bool = true {
        didSet {
            detailsViewController?.shouldLoadRichPopupRelatedRecords = shouldLoadRichPopupRelatedRecords
        }
    }
    
    // MARK: Segmented View Controller
    
    // Returns an array of `SegmentedViewSegue` identifiers telling the segmented view controller which child view controllers to segment and embed.
    override func segmentedViewControllerChildIdentifiers() -> [String] {
        
        guard popupManager != nil else { return [String]() }
        
        var childrenIdentifiers = ["RichPopupDetails"]
        
        if !popupManager.attachmentsNoAccess {
            childrenIdentifiers.append("RichPopupAttachments")
        }
        
        return childrenIdentifiers
    }
    
    // MARK:- Work Mode
    
    @objc
    func adjustViewControllerForWorkMode() {
        // Match the segmented control's tint color with that of the navigation bar's.
        switch appContext.workMode {
        case .online:
            segmentedControl.tintColor = .primary
        case .offline:
            segmentedControl.tintColor = .offline
        }
    }
    
    // MARK: Quick Look
    
    private(set) lazy var previewController: QLPreviewController = { [unowned self] in
        let previewController = QLPreviewController()
        previewController.dataSource = self
        return previewController
    }()
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        title = popupManager.title
        
        // Add dismiss button
        conditionallyAddDismissButton()
        
        // Add edit button
        conditionallyAddEditButton()
        
        // Add delete button
        conditionallyAddDeleteButton()
        
        // Begin listening for app context changes.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustViewControllerForWorkMode),
            name: .workModeDidChange,
            object: nil
        )
        
        // Adjust visuals to reflect current work mode.
        adjustViewControllerForWorkMode()
    }
    
    // MARK: Children
    
    var detailsViewController: RichPopupDetailsViewController!
    
    var attachmentsViewController: RichPopupAttachmentsViewController!
    
    // MARK: Segues (Including Children Segues)
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "RichPopupEditStagedPhotoAttachment" {
            
            guard EphemeralCache.shared.containsObject(forKey: "RichPopupEditStagedPhotoAttachment.EphemeralCacheKey") else {
                
                present(simpleAlertMessage: "Something went wrong, you are unable to edit this attachment.")
                return false
            }
            
            return true
        }
        else if identifier == "RichPopupSelectRelatedRecord" {
            
            guard EphemeralCache.shared.containsObject(forKey: "RichPopupSelectRelatedRecord.EphemeralCacheKey") else {
                
                present(simpleAlertMessage: "Something went wrong, you are unable to edit this related record.")
                return false
            }
            return true
        }
        else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let details = segue.destination as? RichPopupDetailsViewController {
            
            details.delegate = self
            details.popupManager = self.popupManager
            details.shouldLoadRichPopupRelatedRecords = shouldLoadRichPopupRelatedRecords
            
            self.detailsViewController = details
        }
        else if let attachments = segue.destination as? RichPopupAttachmentsViewController {
            
            attachments.delegate = self
            attachments.popupManager = self.popupManager
            
            // Begin loading attachments on background thread.
            attachments.popupAttachmentsManager.load(completion: nil)
            
            self.attachmentsViewController = attachments
        }
        else if let edit = segue.destination as? RichPopupEditStagedAttachmentViewController {
            
            if let attachment = EphemeralCache.shared.object(forKey: "RichPopupEditStagedPhotoAttachment.EphemeralCacheKey") as? RichPopupStagedAttachment {
                edit.stagedAttachment = attachment as RichPopupStagedAttachment
            }
        }
        else if let related = segue.destination as? RichPopupSelectRelatedRecordViewController {
            
            if let (popups, current) = EphemeralCache.shared.object(forKey: "RichPopupSelectRelatedRecord.EphemeralCacheKey") as? ([AGSPopup], AGSPopup?) {
                related.popups = popups
                related.currentRelatedPopup = current
                related.delegate = self
            }
        }
    }

    private func updateViewControllerUI(animated: Bool) {
        
        super.setEditing(popupManager.isEditing, animated: animated)
        
        if self.popupManager.isEditing {
            // Add Cancel button. Will hide back bar button, if there is one.
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(userRequestsCancelEditingPopup))
        }
        else {
            // Removes Cancel button, if there is one. Will replace back bar button with dismiss bar button, if there is one.
            self.navigationItem.leftBarButtonItem = self.dismissButton
        }
        
        // Inform the view controller not to dismiss the view controller if editing.
        isModalInPresentation = self.popupManager.isEditing
        
        // If this is a newly added record, we will need to add a delete button.
        conditionallyAddDeleteButton()
    }
    
    // MARK: Edit Pop-up
    
    private func conditionallyAddEditButton() {
        
        if popupManager.shouldAllowEdit {
            navigationItem.rightBarButtonItem = editButtonItem
        }
    }
    
    // This function is called when the `editButtonItem` is tapped. The `editButtonItem` is tapped only to start or finish (save) an edit session.
    // This function will not be called when the user would like to cancel an edit session.
    override func setEditing(_ editing: Bool, animated: Bool) {
        self.setEditing(editing, animated: animated, persist: true)
    }
    
    @objc func userRequestsCancelEditingPopup(_ sender: Any) {
        self.setEditing(false, animated: true, persist: false)
    }
    
    // Adding the persist flag introduces the ability to 'cancel' an edit session, as is supported by the pop-up manager.
    private func setEditing(_ editing: Bool, animated: Bool, persist: Bool) {
        
        self.detailsViewController?.resignCurrentFirstResponder()
        
        if editing {
            
            // User is requesting to begin an editing session.
            defer {
                self.updateViewControllerUI(animated: animated)
            }
        
            // User is requesting to start an editing session.
            guard popupManager.shouldAllowEdit, popupManager.startEditing() else {
                self.present(simpleAlertMessage: "Could not edit pop-up.")
                return
            }
        }
        else if persist {
            
            // User is requesting to finish (and save) the editing session.
            disableUserInteraction(status: "Saving Record")
            
            // User is requesting to finish an editing session.
            finishEditingAndPersistRecord { [weak self] (error) in
                
                guard let self = self else { return }
                
                self.enableUserInteraction()

                if let error = error {
                                        
                    self.present(simpleAlertMessage: "Could not save record. \(error.localizedDescription)")
                }
                
                self.updateViewControllerUI(animated: animated)
            }
        }
        else {
            
            // User is requesting to cancel an editing session.
            // Ask them for confirmation first.
            confirmCancelEditingSession() { [weak self] (error) in
                
                guard let self = self else { return }
                
                if let error = error {
                    self.present(simpleAlertMessage: "Something went wrong. \(error.localizedDescription)")
                }
                
                // If the feature is not added to the the table, we can dismiss the view controller.
                if (!self.popupManager.popup.isFeatureAddedToTable) {
                    
                    // Dismiss the view controller.
                    self.popOrDismiss(animated: true)
                }
                else {
                    self.updateViewControllerUI(animated: animated)
                }
            }
        }
    }
    
    private func confirmCancelEditingSession(_ completion: ((Error?) -> Void)? = nil) {
        
        let cancelAction: ((UIAlertAction) -> Void) = { [weak self] (_) in
            
            guard let self = self else { return }
            
            self.popupManager.cancelEditing()
            
            completion?(nil)
        }
        
        present(confirmationAlertMessage: "Discard changes?", confirmationTitle: "Discard", confirmationAction: cancelAction)
    }
    
    // MARK: Delete Pop-up
    
    private var deleteButton: UIBarButtonItem?
    
    private func conditionallyAddDeleteButton() {
        
        if popupManager.shouldAllowDelete, deleteButton == nil {
            
            // Reveal toolbar
            navigationController?.isToolbarHidden = false
            
            // Add delete bar button item with flexible space on either side
            var items = [UIBarButtonItem]()
            
            items.append( UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) )
            
            let delete = UIBarButtonItem(title: String(format: "Delete %@", popupManager.title ?? "Record"),
                                     style: .plain,
                                    target: self,
                                    action: #selector(userRequestsDeletePopup(_:)))
            
            delete.tintColor = .destructive
            items.append( delete )
            
            items.append( UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) )
            
            deleteButton = delete

            toolbarItems = items
        }
    }
    
    @objc func userRequestsDeletePopup(_ sender: AnyObject) {
        
        confirmDeleteRecord { [weak self] (error) in
            
            guard let self = self else { return }
            
            if let error = error {
                self.present(simpleAlertMessage: "Could not delete record. \(error.localizedDescription)")
            }
            else {
                self.popOrDismiss(animated: true)
            }
        }
    }
    
    private func confirmDeleteRecord(_ completion: ((Error?) -> Void)? = nil) {
        
        let deleteAction: ((UIAlertAction) -> Void) = { [weak self] (_) in
            
            guard let self = self else { return }

            self.disableUserInteraction(status: "Deleting Record")

            self.deleteRecord() { [weak self] (error) in
                
                guard let self = self else { return }

                self.enableUserInteraction()
                
                self.popupManager.conditionallyPerformCustomBehavior { completion?(error) }
            }
        }
        
        present(confirmationAlertMessage: String(format: "Delete %@", popupManager.title ?? "Record"), confirmationTitle: "Delete", confirmationAction: deleteAction)
    }
    
    // MARK: Activity Status (Async load, save, delete)
    
    func disableUserInteraction(status: String?) {
        
        // Disable contents of view (children)
        view.isUserInteractionEnabled = false
        
        // Disable interaction with the view controller.
        deleteButton?.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.backBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        if let status = status {
            // Display status message with activity indicator.
            SVProgressHUD.show(withStatus: status)
        }
    }
    
    func enableUserInteraction() {
        
        // Enable contents of view (children)
        view.isUserInteractionEnabled = true
        
        // Disable interaction with the view controller.
        deleteButton?.isEnabled = true
        navigationItem.leftBarButtonItem?.isEnabled = true
        navigationItem.backBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        // Display status message with activity indicator.
        SVProgressHUD.dismiss(withDelay: 0.2)
    }
    
    // MARK: Dismiss View Controller
    
    private var dismissButton: UIBarButtonItem?
    
    private func conditionallyAddDismissButton() {
        
        if isRootViewController {
            
            // Build dismiss button
            dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(userRequestsDismissViewController(_:)))
            
            if !isEditing {
                // Assign left bar button
                navigationItem.leftBarButtonItem = dismissButton
            }
        }
    }
    
    @objc func userRequestsDismissViewController(_ sender: AnyObject) {
        
        self.popOrDismiss(animated: true)
    }
    
    // MARK: Image Picker Permissions
    
    private(set) lazy var imagePickerPermissions: ImagePickerPermissions = { [unowned self] in
        var imagePickerPermissions = ImagePickerPermissions()
        imagePickerPermissions.delegate = self
        return imagePickerPermissions
    }()
    
    var isProcessingNewAttachmentImage: Bool = false
}
