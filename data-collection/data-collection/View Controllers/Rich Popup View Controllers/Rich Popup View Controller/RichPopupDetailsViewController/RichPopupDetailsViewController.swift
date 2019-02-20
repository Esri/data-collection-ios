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
import ArcGIS

protocol RichPopupDetailsViewControllerDelegate: AnyObject {
    func detailsViewController(_ detailsViewController: RichPopupDetailsViewController, selectedEditManyToOneRelationship relationship: ManyToOneRelationship)
    func detailsViewController(_ detailsViewController: RichPopupDetailsViewController, selectedViewRelatedPopup manager: RichPopupManager)
    func detailsViewController(_ detailsViewController: RichPopupDetailsViewController, selectedAddNewOneToManyRelatedRecordForRelationship relationship: OneToManyRelationship)
}

class RichPopupDetailsViewController: UITableViewController {
    
    var popupManager: RichPopupManager!
    
    var shouldLoadRichPopupRelatedRecords: Bool = true
    
    var delegate: RichPopupDetailsViewControllerDelegate?
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The contents of a pop-up field is dynamic and thus the size of a table view cell's content view must be able to change.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload the table view every time the view will appear.
        if shouldLoadRichPopupRelatedRecords {
            
            // Load relationships before reloading table view.
            if let relationships = popupManager.richPopup.relationships {
                
                relationships.load { [weak self] (error) in
                    guard let self = self else { return }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    weak var currentFirstResponder: UIResponder?
    
    func resignCurrentFirstResponder() {
        
        if let responder = currentFirstResponder, responder.isFirstResponder {
            responder.resignFirstResponder()
        }
        
        currentFirstResponder = nil
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.tableView.reloadData()
    }
}
