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
import Combine

class RichPopupViewController: SegmentedViewController {
    
    // MARK: Rich Popup
    
    var popupManager: RichPopupManager!
    
    var currentFloatingPanelItem: FloatingPanelItem?
    
    var shouldLoadRichPopupRelatedRecords: Bool = true {
        didSet {
            detailsViewController?.shouldLoadRichPopupRelatedRecords = shouldLoadRichPopupRelatedRecords
        }
    }
    
    // MARK: Editing Subject
    
    let editsMade = PassthroughSubject<Result<RichPopup, Error>, Never>()
    
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
        case .none, .online(_):
            segmentedControl.tintColor = .primary
        case .offline(_):
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
    
    override func viewDidAppear(_ animated: Bool) {
        conditionallyAddToolbarItems()
    }
    
    // MARK: Children
    
    var detailsViewController: RichPopupDetailsViewController!
    
    var attachmentsViewController: RichPopupAttachmentsViewController!
    
    // MARK: Segues (Including Children Segues)
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "RichPopupEditStagedPhotoAttachment" {
            
            guard EphemeralCache.shared.containsObject(forKey: "RichPopupEditStagedPhotoAttachment.EphemeralCacheKey") else {
                showMessage(message: "Something went wrong, you are unable to edit this attachment.")
                return false
            }
            
            return true
        }
        else if identifier == "RichPopupSelectRelatedRecord" {
            
            guard EphemeralCache.shared.containsObject(forKey: "RichPopupSelectRelatedRecord.EphemeralCacheKey") else {
                showMessage(message: "Something went wrong, you are unable to edit this related record.")
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
//
//        // Inform the view controller not to dismiss the view controller if editing.
//        isModalInPresentation = self.popupManager.isEditing
        
        // Update toolbar items.
        conditionallyAddToolbarItems()
    }

    // MARK: Edit Pop-up
    var dismissButton: UIBarButtonItem?

    private func conditionallyAddToolbarItems() {
        var items: [UIBarButtonItem] = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)]
        if popupManager.isEditing {
            // Add Save and Cancel buttons.
            let save = UIBarButtonItem(image: UIImage(named: "save"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(saveEdits(animated:)))
            items.append(save)

            let cancelItem = UIBarButtonItem(image: UIImage(named: "x"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(userRequestsCancelEditingPopup))
            items.append(cancelItem)
        }
        else if popupManager.shouldAllowEdit {
            // Add Edit button.
            let editButton = UIBarButtonItem(image: UIImage(named: "pencil"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(setEditing(animated:)))
            items.append(editButton)
        }
        
        if popupManager.shouldAllowDelete, !popupManager.isEditing {
            // Add Delete button
            let deleteButton = UIBarButtonItem(image: UIImage(named: "trash"),
                                               style: .plain,
                                               target: self,
                                               action: #selector(userRequestsDeletePopup(_:)))
            deleteButton.tintColor = .destructive
            items.append(deleteButton)
        }
        
        if dismissButton == nil {
            dismissButton = UIBarButtonItem(barButtonSystemItem: .done,
                                                target: self,
                                                action: #selector(userRequestsDismissViewController(_:)))
        }
        navigationItem.leftBarButtonItem = popupManager.isEditing ? nil : dismissButton

        
        toolbarItems = items
        navigationController?.isToolbarHidden = items.isEmpty

        currentFloatingPanelItem?.closeButtonHidden = popupManager.isEditing
    }
    
    @objc func setEditing(animated: Bool) {
        setEditing(true, animated: false)
    }
    
    @objc func saveEdits(animated: Bool) {
        setEditing(false, animated: false, persist: true)
    }

    // This function is called when the `editButtonItem` is tapped. The `editButtonItem` is tapped only to start or finish (save) an edit session.
    // This function will not be called when the user would like to cancel an edit session.
    override func setEditing(_ editing: Bool, animated: Bool) {
        self.setEditing(editing, animated: animated, persist: true)
    }
    
    @objc func userRequestsCancelEditingPopup(_ sender: Any) {
        self.setEditing(false, animated: true, persist: false)
    }
    
    struct CannotEditPopupError: LocalizedError {
        var errorDescription: String? { "Cannot edit pop-up." }
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
                showError(CannotEditPopupError())
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
                self.updateViewControllerUI(animated: animated)
                
                if let error = error {
                    self.editsMade.send(.failure(error))
                }
                else {
                    self.editsMade.send(.success(self.popupManager.richPopup))
                }
                
            }
        }
        else {
            
            // User is requesting to cancel an editing session.
            // Ask them for confirmation first.
            confirmCancelEditingSession() { [weak self] (error) in
                
                guard let self = self else { return }
                
                if let error = error {
                    self.showError(error)
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
        
        let alert = UIAlertController(title: nil, message: "Discard changes?", preferredStyle: .alert)
        let discard = UIAlertAction(title: "Discard", style: .destructive) { [weak self] (_) in
            guard let self = self else { return }
            self.popupManager.cancelEditing()
            completion?(nil)
        }
        alert.addAction(.cancel())
        alert.addAction(discard)
        showAlert(alert, animated: true, completion: nil)
    }
    
    @objc func userRequestsDeletePopup(_ sender: AnyObject) {
        
        confirmDeleteRecord { [weak self] (error) in
            
            guard let self = self else { return }
            
            if let error = error {
                self.showError(error)
            }
            else {
                self.popOrDismiss(animated: true)
            }
        }
    }
    
    private func confirmDeleteRecord(_ completion: ((Error?) -> Void)? = nil) {
        
        let alert = UIAlertController(
            title: nil,
            message: String(format: "Delete %@", popupManager.title ?? "Record"),
            preferredStyle: .alert
        )
        
        let delete = UIAlertAction(title: "Delete", style: .destructive) { [weak self] (_) in
            guard let self = self else { return }
            self.disableUserInteraction(status: "Deleting Record")
            self.deleteRecord() { (error) in
                self.enableUserInteraction()
                if let error = error {
                    self.editsMade.send(.failure(error))
                }
                else {
                    self.editsMade.send(.success(self.popupManager.richPopup))
                }
                self.popupManager.conditionallyPerformCustomBehavior { completion?(error) }
            }
        }
        
        alert.addAction(.cancel())
        alert.addAction(delete)
        
        showAlert(alert, animated: true, completion: nil)
    }
    
    // MARK: Activity Status (Async load, save, delete)
    
    func disableUserInteraction(status: String?) {
        
        // Disable contents of view (children)
        view.isUserInteractionEnabled = false
        
        // Disable interaction with the toolbar.
        navigationController?.isToolbarHidden = true

        if let status = status {
            // Display status message with activity indicator.
            SVProgressHUD.show(withStatus: status)
        }
    }
    
    func enableUserInteraction() {
        
        // Enable contents of view (children)
        view.isUserInteractionEnabled = true
        
        // Disable interaction with the toolbar.
        navigationController?.isToolbarHidden = false
        
        // Display status message with activity indicator.
        SVProgressHUD.dismiss(withDelay: 0.2)
    }
    
    // MARK: Dismiss View Controller
    
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

fileprivate extension UIViewController {
    
    func popOrDismiss(animated: Bool, completion: (() -> Void)? = nil) {
        
        if let navigationController = navigationController {
            
            if isRootViewController {
                dismiss(animated: animated, completion: completion)
            }
            else {
                navigationController.popViewController(animated: animated, completion: completion)
            }
        }
        else {
            dismiss(animated: animated, completion: completion)
        }
    }
    
    var isRootViewController: Bool {
        return self == navigationController?.viewControllers.first
    }
}

extension RichPopupViewController: FloatingPanelEmbeddable {
    var floatingPanelItem: FloatingPanelItem {
        let fpItem: FloatingPanelItem
        let top = navigationController?.topViewController as? FloatingPanelEmbeddable
        if self == top {
            if detailsViewController != nil {
                fpItem = detailsViewController.floatingPanelItem
            }
            else {
                fpItem = FloatingPanelItem()
            }
        }
        else if let top = top {
            fpItem = top.floatingPanelItem
        }
        else {
            fpItem = FloatingPanelItem()
        }
        
        currentFloatingPanelItem = fpItem
        return fpItem
    }
}
