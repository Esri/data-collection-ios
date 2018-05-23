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

class RelatedRecordsPopupsViewController: UIViewController {
    
    struct ReuseIdentifiers {
        static let popupIntegerCell = "PopupIntegerCellReuseIdentifier"
        static let popupFloatCell = "PopupFloatCellReuseIdentifier"
        static let popupLongStringCell = "PopupLongTextCellReuseIdentifier"
        static let popupShortStringCell = "PopupShortTextCellReuseIdentifier"
        static let popupDateCell = "PopupDateCellReuseIdentifier"
        static let popupIDCell = "PopupIDCellReuseIdentifier"
        static let relatedRecordCell = "RelatedRecordCellReuseID"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var popupModeButton: UIBarButtonItem!
    
    @IBOutlet weak var adjustableBottomConstraint: NSLayoutConstraint!
    
    weak var parentPopup: AGSPopup?

    var popup: AGSPopup! {
        didSet {
            popupManager = AGSPopupManager(popup: popup)
        }
    }
    
    var popupManager: AGSPopupManager! {
        didSet {
            popupManager.delegate = self
            
            for field in popupManager.editableDisplayFields {
                print(popupManager.fieldType(for: field))
            }
        }
    }
    
    var isRootPopup: Bool {
        return parentPopup == nil
    }
    
    var manyToOneRecords = [RelatedRecordsManager]()
    var oneToManyRecords = [RelatedRecordsManager]()
    
    var loadingRelatedRecords = false {
        didSet {
            popupModeButton.isEnabled = !loadingRelatedRecords
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(PopupIntegerCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupIntegerCell)
        tableView.register(PopupFloatCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupFloatCell)
        tableView.register(PopupLongStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupLongStringCell)
        tableView.register(PopupShortStringCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupShortStringCell)
        tableView.register(PopupDateCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupDateCell)
        tableView.register(PopupIDCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupIDCell)
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Is root popup view controller?
        if isRootPopup {
            self.addBackButton(withSelector: #selector(RelatedRecordsPopupsViewController.dismissRelatedRecordsPopupsViewController(_:)))
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(RelatedRecordsPopupsViewController.adjustKeyboardVisible(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RelatedRecordsPopupsViewController.adjustKeyboardHidden(notification:)), name: .UIKeyboardWillHide, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set Title
        title = popupManager.title

        // Is root popup?
        if isRootPopup {
            
            loadingRelatedRecords = true
            
            popup.loadRelatedRecords { [weak self] (relatedRecords) in
                
                guard let records = relatedRecords else {
                    return
                }

                self?.oneToManyRecords = records.oneToManyLoaded
                self?.manyToOneRecords = records.manyToOneLoaded
                self?.loadingRelatedRecords = false
                self?.tableView.reloadData()
            }
        }
        
        // Finally, load table
        tableView.reloadData()
    }
    
    func indexPathWithinAttributes(_ indexPath: IndexPath) -> Bool {
        
        if indexPath.section == 0 {
            guard indexPath.row >= popupManager.displayFields.count else {
                return true
            }
        }
        
        return false
    }
    
    @IBAction func togglePopupMode(_ sender: Any) {
        
        guard !loadingRelatedRecords else {
            return
        }
        
        // TODO: ensure mode can be alternated

        if popupManager.isEditing {
            
            if let invalids = validatePopup(), invalids.count > 1 {
                print("Invalid fields!")
                // Alert User that popup is invalid.
                for invalid in invalids {
                    print(invalid)
                }
                print("~")
                return
            }
            
            popupManager.cancelEditing()
        }
        else {
            guard popupManager.shouldAllowEdit else {
                return 
            }
            popupManager.startEditing()
        }
        
        popupModeButton.title = popupManager.actionButtonTitle
        tableView.reloadData()
    }
    
    func validatePopup() -> [Error]? {
        
        guard popupManager.isEditing else {
            return nil
        }
        
        var invalids = [Error]()
        
        for field in popupManager.editableDisplayFields {
            if let error = popupManager.validationError(for: field) {
                invalids.append(error)
            }
        }
        
        // TODO enforce M:1 relationships exist.
        
        return invalids
    }
    
    @objc func dismissRelatedRecordsPopupsViewController(_ sender: AnyObject?) {
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

