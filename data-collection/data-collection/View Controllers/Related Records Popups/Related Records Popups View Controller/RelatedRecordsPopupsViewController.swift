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

class RelatedRecordsPopupsViewController: UIViewController, EphemeralCacheCacheable {
    
    // TODO rework ephemeralCacheKey to be owned by the object sent in.
    static var ephemeralCacheKey: String {
        return "EphemeralCache.RelatedRecordsPopupsViewController.TableList.Key"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var popupModeButton: UIBarButtonItem!
    
    @IBOutlet weak var adjustableBottomConstraint: NSLayoutConstraint!
    
    weak var parentPopup: AGSPopup?

    var popup: AGSPopup! {
        didSet {
            recordsManager = PopupRelatedRecordsManager(popup: popup)
        }
    }
    
    var recordsManager: PopupRelatedRecordsManager! {
        didSet {
            recordsTableManager = PopupRelatedRecordsTableManager(withRecordsManager: recordsManager)
        }
    }
    
    var recordsTableManager: PopupRelatedRecordsTableManager!
    
    var editingPopup: Bool {
        get {
            return recordsManager.isEditing
        }
        set {
            if recordsManager.isEditing {
                
                // Will return nil if not editing
                guard let invalids = recordsManager.validatePopup() else {
                    return
                }
                
                // 1. Check Validity
                guard invalids.count == 0 else {
                    self.present(simpleAlertMessage: "You cannot save this \(recordsManager.title ?? "feature"). There \(invalids.count == 1 ? "is" : "are") \(invalids.count) invalid field\(invalids.count == 1 ? "" : "s").")
                    return
                }
                
                // 2. Finish Editing
                recordsManager.finishEditing { [weak self] (error) in
                    
                    guard error == nil else {
                        print("[Error: Validating Feature]", error!.localizedDescription)
                        return
                    }
                    
                    guard
                        let feature = self?.popup.geoElement as? AGSArcGISFeature,
                        let featureTable = feature.featureTable as? AGSArcGISFeatureTable
                        else {
                            // somethign went very wrong
                            // TODO alert
                            return
                    }
                    
                    featureTable.edit(feature: feature, completion: { [weak self] (error) in
                        
                        if error != nil {
                            print("[Error] feature table edit error", error!.localizedDescription)
                        }
                        
                        self?.adjustUI()
                    })
                }
            }
            else {
                
                guard appContext.isLoggedIn else {
                    // TODO login
                    return
                }
                
                guard recordsManager.shouldAllowEdit, recordsManager.startEditing() else {
                    // TODO Inform user that the session couldn't start
                    return
                }
                
                adjustUI()
            }
        }
    }
    
    var isRootPopup: Bool {
        return parentPopup == nil
    }
    
    var loadingRelatedRecords = false {
        didSet {
            popupModeButton.isEnabled = !loadingRelatedRecords
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(PopupReadonlyFieldCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupReadonlyCell)
        tableView.register(PopupNumberCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupNumberCell)
        tableView.register(PopupShortStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupShortTextCell)
        tableView.register(PopupLongStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupLongTextCell)
        tableView.register(PopupDateCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupDateCell)
        tableView.register(PopupIDCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupIDCell)
        tableView.register(PopupCodedValueCell.self, forCellReuseIdentifier: ReuseIdentifiers.codedValueCell)
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // TODO Inject Edit Button only if Editing is enabled
        if recordsManager.shouldAllowEdit {
            popupModeButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(RelatedRecordsPopupsViewController.togglePopupMode(_:)))
            self.navigationItem.rightBarButtonItem = popupModeButton
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(RelatedRecordsPopupsViewController.adjustKeyboardVisible(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RelatedRecordsPopupsViewController.adjustKeyboardHidden(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        // Set Title
        title = recordsManager.title
        
        // Is root popup?
        if isRootPopup {
            
            loadingRelatedRecords = true
            
            recordsManager.loadRelatedRecords { [weak self] in
                
                self?.loadingRelatedRecords = false
                self?.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        adjustUI()
    }
    
    // TODO: reorganize
    private func adjustBackButton() {
        if isRootPopup {
            if recordsManager.isEditing {
                self.addCancelButton(withSelector: #selector(RelatedRecordsPopupsViewController.cancelPopupEditMode(_:)))
            }
            else {
                self.addBackButton(withSelector: #selector(RelatedRecordsPopupsViewController.dismissRelatedRecordsPopupsViewController(_:)))
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? RelatedRecordsListViewController {
            if  let popup = EphemeralCache.get(objectForKey: RelatedRecordsPopupsViewController.ephemeralCacheKey) as? AGSPopup,
                let feature = popup.geoElement as? AGSArcGISFeature,
                let table = feature.featureTable as? AGSArcGISFeatureTable {
                destination.featureTable = table
                destination.delegate = self
            }
        }
    }
    
    @objc func cancelPopupEditMode(_ sender: Any?) {
        
        let alert: UIAlertController!
        
        if popup.isAddedToTable {
            alert = UIAlertController.multiAlert(title: nil, message: "Discard changes?", actionTitle: "Discard", action: { [weak self] (_) in
                self?.recordsManager.cancelEditing()
                self?.adjustUI()
                }, cancelTitle: "Cancel", cancel: nil)
        }
        else {
            alert = UIAlertController.multiAlert(title: nil, message: "Discard changes?", actionTitle: "Discard", action: { [weak self] (_) in
                self?.dismiss(animated: true, completion: nil)
                }, cancelTitle: "Cancel", cancel: nil)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func togglePopupMode(_ sender: Any) {
        editingPopup = !editingPopup
    }
    
    func adjustUI() {
        
        if popupModeButton != nil {
            popupModeButton.title = recordsManager.actionButtonTitle
        }
        
        if tableView != nil {
            tableView.reloadData()
        }
        
        adjustBackButton()
    }
    
    @objc func dismissRelatedRecordsPopupsViewController(_ sender: AnyObject?) {
        guard !recordsManager.isEditing else {
            // TODO Alert!
            self.present(simpleAlertMessage: "You must save first!")
            // TODO Save
            return
        }
        dismiss(animated: true, completion: nil)
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

extension RelatedRecordsPopupsViewController: RelatedRecordsListViewControllerDelegate {
    
    func relatedRecordsListViewController(_ viewController: RelatedRecordsListViewController, didSelectPopup relatedPopup: AGSPopup) {
        
        _ = navigationController?.popViewController(animated: true)
        
        guard let info = self.popup.relationship(withPopup: relatedPopup) else {
            // TODO alert user
            return
        }
        
        do {
            try recordsManager.update(manyToOne: relatedPopup, forRelationship: info)
        }
        catch {
            print("[Error] couldn't update related record", error.localizedDescription)
            // TODO alert user
        }
        
        tableView.reloadData()
    }
}
