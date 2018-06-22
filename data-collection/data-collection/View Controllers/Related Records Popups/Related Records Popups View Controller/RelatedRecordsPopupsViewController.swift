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

class RelatedRecordsPopupsViewController: AppContextAwareController, BackButtonDelegate {
    
    private typealias VC = RelatedRecordsPopupsViewController
    
    struct EphemeralCacheKeys {
        static let tableList = "EphemeralCache.RelatedRecordsPopupsViewController.TableList.Key"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var popupModeButton: UIBarButtonItem?
    
    @IBOutlet weak var adjustableBottomConstraint: NSLayoutConstraint!
    
    var popup: AGSPopup! {
        didSet {
            recordsManager = PopupRelatedRecordsManager(popup: popup)
        }
    }
    
    var parentRecordsManager: PopupRelatedRecordsManager?
    
    var recordsManager: PopupRelatedRecordsManager!
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(VC.adjustKeyboardVisible(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VC.adjustKeyboardHidden(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        tableView.register(PopupReadonlyFieldCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupReadonlyCell)
        tableView.register(PopupNumberCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupNumberCell)
        tableView.register(PopupShortStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupShortTextCell)
        tableView.register(PopupLongStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupLongTextCell)
        tableView.register(PopupDateCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupDateCell)
        tableView.register(PopupIDCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupIDCell)
        tableView.register(PopupCodedValueCell.self, forCellReuseIdentifier: ReuseIdentifiers.codedValueCell)
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        tableView.register(DeleteRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.deletePopupCell)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if recordsManager.shouldAllowEdit {
            popupModeButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(VC.userRequestsTogglePopupMode(_:)))
            self.navigationItem.rightBarButtonItem = popupModeButton
        }
        
        if isRootViewController {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(VC.userTappedRootLeftBarButton(_:)))
        }
        
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
        
        if let destination = segue.destination as? RelatedRecordsListViewController {
            if let table = EphemeralCache.get(objectForKey: EphemeralCacheKeys.tableList) as? AGSArcGISFeatureTable {
                destination.featureTable = table
                destination.delegate = self
            }
        }
    }
    
    func interceptNavigationBackActionShouldPopViewController() -> Bool {
        
        let shouldPop = !recordsManager.isEditing
        
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
    
    func endPopupEditMode(_ completion: ((_ shouldDismiss: Bool) -> Void)? = nil) {

        var action: ((UIAlertAction) -> Void)!
        
        if popup.isFeatureAddedToTable {
            action = { [weak self] (_) in
                self?.recordsManager.cancelEditing()
                self?.adjustViewControllerForEditState()
                completion?(false)
            }
        }
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
            popupModeButton?.title = recordsManager.actionButtonTitle
        }
        
        if tableView != nil {
            tableView.reloadData()
        }
        
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
    
    @objc func adjustKeyboardVisible(notification: NSNotification) {
        print("[Keyboard] \(notification.name.rawValue)")
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let heightDelta = keyboardFrame.cgRectValue.height
            adjustableBottomConstraint.constant = -heightDelta
        }
    }
    
    @objc func adjustKeyboardHidden(notification: NSNotification) {
        print("[Keyboard] \(notification.name.rawValue)")
        adjustableBottomConstraint.constant = 0
    }
    
    deinit {
        // Remove All Observers
        NotificationCenter.default.removeObserver(self)
    }
}

