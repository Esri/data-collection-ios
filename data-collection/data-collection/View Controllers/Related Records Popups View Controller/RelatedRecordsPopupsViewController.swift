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
        static let popupTextField = "PopupTextFieldReuseID"
        static let relatedRecordCell = "RelatedRecordCellReuseID"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var popup: AGSPopup! {
        didSet {
            popupManager = AGSPopupManager(popup: popup)
        }
    }
    
    var popupManager: AGSPopupManager!
    
    weak var previousPopup: AGSPopup?
    
    var isRootPopup: Bool {
        return previousPopup == nil
    }
    
    var manyToOneRecords = [RelatedRecordsManager]()
    var oneToManyRecords = [RelatedRecordsManager]()
    
    var loadingRelatedRecords = false
    
    func loadRelatedRecordsIntoTableView() {
        
        // TODO make swifty ?
        // TODO fix
        
        var rows = [IndexPath]()
        for i in 0..<manyToOneRecords.count {
            rows.append( IndexPath(row: i+popupManager.displayFields.count, section: 0) )
        }
        
        for i in 0..<oneToManyRecords.count {
            let manager = oneToManyRecords[i]
            for j in 0..<manager.popups.count {
                rows.append( IndexPath(row: j, section: i+1) )
            }
        }
        
        let sections = IndexSet(integersIn: 1...oneToManyRecords.count)
        
        tableView.beginUpdates()
        tableView.insertSections(sections, with: UITableViewRowAnimation.top)
        tableView.insertRows(at: rows, with: UITableViewRowAnimation.top)
        tableView.endUpdates()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(PopupTextFieldCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupTextField)
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Is root popup view controller?
        if isRootPopup {
            guard let image = UIImage(named: "Cancel") else {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .done, target: self, action: #selector(RelatedRecordsPopupsViewController.exitRR(_:)))
                return
            }
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(RelatedRecordsPopupsViewController.exitRR(_:)))
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        tableView.isEditing = true
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set Title
        title = popupManager.title
        
        // Kick off load of related records
        var preloadedRelatedRecords = [RelatedRecordsManager]()
        if let feature = popup.geoElement as? AGSArcGISFeature, let relatedRecordsInfos = feature.relatedRecordsInfos, let map = appContext.currentMap {
            for info in relatedRecordsInfos {
                // TODO work this rule into AppRules
                if map.isPopupEnabledFor(relationshipInfo: info), let relatedRecord = RelatedRecordsManager(relationshipInfo: info, feature: feature) {
                    preloadedRelatedRecords.append(relatedRecord)
                }
            }
        }
        
        // Is root popup?
        if isRootPopup {
            
            loadingRelatedRecords = true
            
            AGSLoadObjects(preloadedRelatedRecords) { [weak self] (loaded) in
                self?.oneToManyRecords = preloadedRelatedRecords.oneToManyLoaded
                self?.manyToOneRecords = preloadedRelatedRecords.manyToOneLoaded
                self?.loadingRelatedRecords = false
                self?.tableView.reloadData()
                
                // TODO : make this work
//                self?.loadRelatedRecordsIntoTableView()
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
    
    @objc func exitRR(_ sender: AnyObject?) {
        dismiss(animated: true, completion: nil)
    }
}

