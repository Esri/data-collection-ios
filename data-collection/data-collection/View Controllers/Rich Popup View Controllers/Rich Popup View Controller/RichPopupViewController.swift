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

class RichPopupViewController: UITableViewController, BackButtonDelegate {
    
    struct EphemeralCacheKeys {
        static let tableList = "EphemeralCache.RichPopupViewController.TableList.Key"
    }
    
    // MARK: Pop-up and Parent Pop-up
    
    // We want to hang on to references to the pop-up manager and the parent pop-up manager.
    // This way, if there are changes to the pop-up in question, if it is related to another record,
    // that record can update accordingly.
    
    // The pop-up in question.
    // Considered the "child" if related to the `parentPopup`.
    var popup: RichPopup! {
        didSet {
            popupManager = RichPopupManager(richPopup: popup)
        }
    }
    
    private(set) var popupManager: RichPopupManager!
    
    // The parent pop-up.
    var parentPopup: RichPopup? {
        didSet {
            if let parentPopup = parentPopup {
                parentPopupManager = RichPopupManager(richPopup: parentPopup)
            }
            else {
                parentPopupManager = nil
            }
        }
    }
    
    private(set) var parentPopupManager: RichPopupManager?
    
    var shouldBeginEditPopupUponLoad: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = popupManager.title
        
        // Register the various table cell types.
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
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        
        // Editing is enabled only if the pop-up in question can be edited.
        if !popupManager.shouldAllowEdit {
            removeEditBarButtonItem()
        }
        
        // A root view controller does not contain a back button. If this is the case, we want to build a dimiss/cancel button.
        if isRootViewController {
            addDismissalLeftBarButtonItem()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadRichPopupRelationships()
    }
    
    private func loadRichPopupRelationships() {
        
        if parentPopupManager == nil, let relationships = popup.relationships {
            
            popupEditButton?.isEnabled = false
            
            relationships.load { [weak self] (error) in
                
                guard let self = self else { return }
                
                self.popupEditButton?.isEnabled = true
                
                if let error = error {
                    self.present(simpleAlertMessage: error.localizedDescription)
                }
                
                self.beginEditingSessionIfRequested()
            }
        }
        else {
            self.beginEditingSessionIfRequested()
        }
    }
    
    private func beginEditingSessionIfRequested() {
        
        if shouldBeginEditPopupUponLoad {
            
            shouldBeginEditPopupUponLoad = false
            beginEditingSession()
        }
        
        adjustViewControllerForEditingState()
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
        let shouldPop = !popupManager.isEditing
        
        // If the pop-up is being edited, we want to ask the user if they want to end the pop-up editing session.
        if !shouldPop {
            
            cancelEditingSession() { [weak self] _ in
                
                guard let self = self else { return }
                
                self.popDismiss()
            }
        }
        
        return shouldPop
    }
    
    // MARK: Edit Mode UI
    
    @IBOutlet weak var popupEditButton: UIBarButtonItem?
    
    private func removeEditBarButtonItem() {
        
        let barButtonIndex = navigationItem.rightBarButtonItems?.firstIndex(where: { (barButtonItem) -> Bool in
            return barButtonItem == popupEditButton
        })
        
        if let index = barButtonIndex {
            navigationItem.rightBarButtonItems?.remove(at: index)
        }
        
        popupEditButton = nil
    }
    
    @IBAction func userRequestsTogglePopupMode(_ sender: Any) {
        
        if !popupManager.isEditing {
            
            beginEditingSession()
            
            adjustViewControllerForEditingState()
        }
        else {
            
            finishEditingSession() { [weak self] _ in
                
                guard let self = self else { return }
                
                self.adjustViewControllerForEditingState()
            }
        }
    }
    
    // MARK: Left Bar Button Item & Dismissal
    
    
    private func addDismissalLeftBarButtonItem() {
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(RichPopupViewController.userTappedRootLeftBarButton(_:)))
    }
    
    // This function is only performed if the view controller is the root view controller of it's navigation controller.
    @objc func userTappedRootLeftBarButton(_ sender: Any?) {
        
        if popupManager.isEditing {
            
            cancelEditingSession() { [weak self] (shouldDismiss) in
                
                guard let self = self else { return }
                
                if shouldDismiss {
                    self.popDismiss()
                }
                else {
                    self.adjustViewControllerForEditingState()
                }
            }
        }
        else {
            popDismiss()
        }
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

