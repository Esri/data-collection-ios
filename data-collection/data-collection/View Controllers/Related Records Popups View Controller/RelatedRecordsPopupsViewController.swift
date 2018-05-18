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
    
    weak var parentPopup: AGSPopup?

    var popup: AGSPopup! {
        didSet {
            popupManager = AGSPopupManager(popup: popup)
        }
    }
    
    var popupManager: AGSPopupManager!
    
    var isRootPopup: Bool {
        return parentPopup == nil
    }
    
    var manyToOneRecords = [RelatedRecordsManager]()
    var oneToManyRecords = [RelatedRecordsManager]()
    
    var loadingRelatedRecords = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(PopupTextFieldCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupTextField)
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Is root popup view controller?
        if isRootPopup {
            guard let image = UIImage(named: "Cancel") else {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .done, target: self, action: #selector(RelatedRecordsPopupsViewController.dismissRelatedRecordsPopupsViewController(_:)))
                return
            }
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(RelatedRecordsPopupsViewController.dismissRelatedRecordsPopupsViewController(_:)))
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
        if let feature = popup.geoElement as? AGSArcGISFeature, let relatedRecordsInfos = feature.relatedRecordsInfos, let featureTable = feature.featureTable as? AGSArcGISFeatureTable {
            for info in relatedRecordsInfos {
                // TODO work this rule into AppRules
                if featureTable.isPopupEnabledFor(relationshipInfo: info), let relatedRecord = RelatedRecordsManager(relationshipInfo: info, feature: feature) {
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
    
    @objc func dismissRelatedRecordsPopupsViewController(_ sender: AnyObject?) {
        dismiss(animated: true, completion: nil)
    }
}

