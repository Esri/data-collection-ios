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

import UIKit
import ArcGIS

protocol RelatedRecordsListViewControllerDelegate {
    func relatedRecordsListViewController(_ viewController: RelatedRecordsListViewController, didSelectPopup popup: AGSPopup)
    func relatedRecordsListViewControllerDidCancel(_ viewController: RelatedRecordsListViewController)
}

class RelatedRecordsListViewController: UIViewController {
    
    var delegate: RelatedRecordsListViewControllerDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var featureTable: AGSArcGISFeatureTable? {
        didSet {
            guard let table = featureTable else {
                featureTableRecordsManager = nil
                return
            }
            featureTableRecordsManager = RelatedRecordsTableManager(featureTable: table)
        }
    }
    
    var featureTableRecordsManager: RelatedRecordsTableManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        
        title = featureTable?.tableName
        
        loadRecords()
    }
    
    func loadRecords() {
        
        SVProgressHUD.show(withStatus: "Loading Records...")
        
        featureTableRecordsManager?.load { [weak self] (error) in
            
            guard error == nil else {
                print("[Error: Feature Table Records manager]", error!.localizedDescription)
                return
            }
            
            self?.tableView.reloadData()
            SVProgressHUD.dismiss()
        }
    }
}

extension RelatedRecordsListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let relatedRecordCell = tableView.cellForRow(at: indexPath) as? RelatedRecordCell, let popup = relatedRecordCell.popup else {
            let alert = UIAlertController.simpleAlert(title: nil, message: "Uh Oh! An unknown error occurred.", actionTitle: "OK") { [weak self] (_) in
                self?.delegate?.relatedRecordsListViewControllerDidCancel(self!)
            }
            present(alert, animated: true, completion: nil)
            return
        }
        
        delegate?.relatedRecordsListViewController(self, didSelectPopup: popup)
    }
}

extension RelatedRecordsListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return featureTableRecordsManager?.popups.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
        cell.popup = featureTableRecordsManager?.popups[indexPath.row]
        cell.maxAttributes = 2
        cell.updateCellContent()
        return cell
    }
}
