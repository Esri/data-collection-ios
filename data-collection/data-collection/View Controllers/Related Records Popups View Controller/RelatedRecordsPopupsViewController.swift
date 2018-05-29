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
    
    var recordsManager: PopupRelatedRecordsManager!
    
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
        tableView.register(PopupStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupTextCell)
        tableView.register(PopupDateCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupDateCell)
        tableView.register(PopupIDCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupIDCell)
        tableView.register(PopupCodedValueCell.self, forCellReuseIdentifier: ReuseIdentifiers.codedValueCell)
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Is root popup view controller?
        if isRootPopup {
            adjustBackButton()
        }
        
        // TODO Inject Edit Button only if Editing is enabled
        if recordsManager.shouldAllowEdit {
            popupModeButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(RelatedRecordsPopupsViewController.togglePopupMode(_:)))
            self.navigationItem.rightBarButtonItem = popupModeButton
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(RelatedRecordsPopupsViewController.adjustKeyboardVisible(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RelatedRecordsPopupsViewController.adjustKeyboardHidden(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    private func adjustBackButton() {
        if recordsManager.isEditing {
            self.addCancelButton(withSelector: #selector(RelatedRecordsPopupsViewController.cancelPopupEditMode(_:)))
        }
        else {
            self.addBackButton(withSelector: #selector(RelatedRecordsPopupsViewController.dismissRelatedRecordsPopupsViewController(_:)))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        // Finally, load table
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? RelatedRecordsListViewController {
            if
                let popup = EphemeralCache.get(objectForKey: RelatedRecordsPopupsViewController.ephemeralCacheKey) as? AGSPopup,
                let feature = popup.geoElement as? AGSArcGISFeature,
                let table = feature.featureTable as? AGSArcGISFeatureTable {
                destination.featureTable = table
                destination.delegate = self
            }
        }
    }
    
    @objc func cancelPopupEditMode(_ sender: Any?) {
        
        recordsManager.cancelEditing()
        
        adjustUI()
    }
    
    @objc func togglePopupMode(_ sender: Any) {
        
        guard !loadingRelatedRecords, recordsManager.shouldAllowEdit else {
            return
        }
        
        if recordsManager.isEditing {
            
            guard let invalids = recordsManager.validatePopup() else {
                return
            }
            
            guard invalids.count == 0 else {
                self.present(simpleAlertMessage: "You cannot save this \(recordsManager.title ?? "feature"). There \(invalids.count == 1 ? "is" : "are") \(invalids.count) invalid field\(invalids.count == 1 ? "" : "s").")
                return
            }
            
            recordsManager.finishEditing { [weak self] (error) in
                
                if let err = error {
                    print("[Error: Validating Feature]", err.localizedDescription)
                }
                
                self?.adjustUI()
            }
        }
        else {
            
            guard recordsManager.shouldAllowEdit else {
                return 
            }
            
            guard recordsManager.startEditing() else {
                // TODO Inform user that the session couldn't start
                return
            }
            
            adjustUI()
        }
    }
    
    func adjustUI() {
        
        popupModeButton.title = recordsManager.actionButtonTitle
        tableView.reloadData()
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

// TODO wrap within RelatedRecordsManager
extension RelatedRecordsPopupsViewController: RelatedRecordsListViewControllerDelegate {
    
    func relatedRecordsListViewController(_ viewController: RelatedRecordsListViewController, didSelectPopup popup: AGSPopup) {
        print("New related record", popup)
    }
}
