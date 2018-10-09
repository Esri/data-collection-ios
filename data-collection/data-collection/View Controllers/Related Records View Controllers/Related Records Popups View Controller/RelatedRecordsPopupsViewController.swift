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

class RelatedRecordsPopupsViewController: UITableViewController, BackButtonDelegate {
    
    private typealias VC = RelatedRecordsPopupsViewController
    
    struct EphemeralCacheKeys {
        static let tableList = "EphemeralCache.RelatedRecordsPopupsViewController.TableList.Key"
    }
    
    var popupModeButton: UIBarButtonItem?
    
    // The popup in question.
    var popup: AGSPopup! {
        didSet {
            recordsManager = PopupRelatedRecordsManager(popup: popup)
        }
    }
    
    // We want to hang on to references to the records manager and the parent records manager.
    // This way, if there are changes to the pop-up in question, if it is related to another record,
    // that record can update accordingly.
    var parentRecordsManager: PopupRelatedRecordsManager?
    var recordsManager: PopupRelatedRecordsManager!
    
    // We only want to load related records from the top level identify.
    var shouldLoadRelatedRecords: Bool {
        return parentRecordsManager == nil
    }
    
    var loadingRelatedRecords = false {
        didSet {
            popupModeButton?.isEnabled = !loadingRelatedRecords
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = recordsManager.title
        
        tableView.register(PopupReadonlyFieldCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupReadonlyCell)
        tableView.register(PopupNumberCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupNumberCell)
        tableView.register(PopupShortStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupShortTextCell)
        tableView.register(PopupLongStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupLongTextCell)
        tableView.register(PopupDateCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupDateCell)
        tableView.register(PopupIDCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupIDCell)
        tableView.register(PopupCodedValueCell.self, forCellReuseIdentifier: ReuseIdentifiers.codedValueCell)
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        tableView.register(DeleteRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.deletePopupCell)
        
        // The contents of a pop-up field is dynamic and thus the size of a table view cell's content view must be able to change.
        tableView.rowHeight = UITableView.automaticDimension
        
        // Editing is enabled only if the pop-up in question can be edited.
        if recordsManager.shouldAllowEdit {
            popupModeButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(VC.userRequestsTogglePopupMode(_:)))
            self.navigationItem.rightBarButtonItem = popupModeButton
        }
        
        // A root view controller does not contain a back button.
        // If this is the case, we want to build a cancel button.
        if isRootViewController {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(VC.userTappedRootLeftBarButton(_:)))
        }
        
        // Load related records.
        if shouldLoadRelatedRecords {
            loadingRelatedRecords = true
            recordsManager.loadRelatedRecords { [weak self] in
                self?.loadingRelatedRecords = false
                self?.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        adjustViewControllerForEditState()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // This unwraps if the user is editing a many-to-one record.
        // A table view is presented with all records from the many-to-one table, for selection.
        if let destination = segue.destination as? RelatedRecordsListViewController {
            if let table = EphemeralCache.get(objectForKey: EphemeralCacheKeys.tableList) as? AGSArcGISFeatureTable {
                destination.featureTable = table
                destination.delegate = self
            }
        }
    }
    
    // This function allows the view controller to intercept and stop the navigation controller from popping the view controller, should certain conditions not be met.
    func interceptNavigationBackActionShouldPopViewController() -> Bool {
        
        // The view controller should be popped if the pop-up is not being edited.
        let shouldPop = !recordsManager.isEditing
        
        // If the pop-up is being edited, we want to ask the user if they want to end the pop-up editing session.
        if !shouldPop {
            endPopupEditMode() { [weak self] _ in
                self?.popDismiss()
            }
        }
        
        return shouldPop
    }
    
    // MARK : View / Edit Mode
    
    @objc func userRequestsTogglePopupMode(_ sender: Any) {
        
        toggleEditPopup()
    }
    
    func toggleEditPopup(_ completion: ((_ success: Bool) -> Void)? = nil) {
        
        editPopup(!recordsManager.isEditing, completion: completion)
    }
    
    // MARK : Editing Popup UI
    
    // This function is only performed if the view controller is the root view controller of it's navigation controller.
    @objc func userTappedRootLeftBarButton(_ sender: Any?) {
        
        if recordsManager.isEditing {
            endPopupEditMode() { [weak self] (shouldDismiss) in
                if shouldDismiss {
                    self?.popDismiss()
                }
            }
        }
        else {
            popDismiss()
        }
    }
    
    // This checks if the pop-up in question is newly created and the user no longer wants to save or,
    // if the pop-up is already a member of the table.
    private func endPopupEditMode(_ completion: ((_ shouldDismiss: Bool) -> Void)? = nil) {

        let action: ((UIAlertAction) -> Void)
        
        // If the pop-up is already a member, we want to cancel editing of the pop-up and not dismiss the view controller.
        if popup.isFeatureAddedToTable {
            action = { [weak self] (_) in
                self?.recordsManager.cancelEditing()
                self?.adjustViewControllerForEditState()
                completion?(false)
            }
        }
        // If the pop-up is not a member, we can discard the pop-up altogether and dismiss the view controller.
        else {
            action = { (_) in
                completion?(true)
            }
        }
        present(confirmationAlertMessage: "Discard changes?", confirmationTitle: "Discard", confirmationAction: action)
    }
    
    // MARK : UI
    
    func adjustViewControllerForEditState() {
        
        if popupModeButton != nil {
            popupModeButton?.title = recordsManager.isEditing ? "Done" : "Edit"
        }
        
        tableView.reloadData()
        
        guard isRootViewController else {
            return
        }
        
        if recordsManager.isEditing {
            self.navigationItem.leftBarButtonItem?.style = .plain
            self.navigationItem.leftBarButtonItem?.title = "Cancel"
        }
        else {
            self.navigationItem.leftBarButtonItem?.style = .done
            self.navigationItem.leftBarButtonItem?.title = "Dismiss"
        }
    }
    
    @objc func userRequestsDismissRelatedRecordsPopupsViewController(_ sender: AnyObject?) {
        dismiss(animated: true, completion: nil)
    }
    
    func popDismiss(animated: Bool = true) {
        if isRootViewController {
            dismiss(animated: animated, completion: nil)
        }
        else {
            navigationController?.popViewController(animated: animated)
        }
    }
}

