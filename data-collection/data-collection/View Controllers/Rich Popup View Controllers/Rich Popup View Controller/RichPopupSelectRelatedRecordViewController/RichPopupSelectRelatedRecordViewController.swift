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

import ArcGIS
import UIKit

protocol RichPopupSelectRelatedRecordViewControllerDelegate: AnyObject {
    func richPopupSelectRelatedRecordViewController(_ richPopupSelectRelatedRecordViewController: RichPopupSelectRelatedRecordViewController, didSelectPopup popup: AGSPopup)
}

class RichPopupSelectRelatedRecordViewController: UITableViewController {
    
    var popups: [AGSPopup]!
    
    var currentRelatedPopup: AGSPopup?
    
    weak var delegate: RichPopupSelectRelatedRecordViewControllerDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let current = currentRelatedPopup, let index = popups.firstIndex(where: { $0 == current }) {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return popups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "PopupSelectRelatedRecordCell", for: indexPath) as! PopupSelectRelatedRecordCell
        let popup = popups[indexPath.row]
        
        let attributes = AGSPopupManager.generateDisplayAttributes(forPopup: popup, max: 2)
        cell.set(attributes: attributes)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let popup = popups[indexPath.row]
        delegate?.richPopupSelectRelatedRecordViewController(self, didSelectPopup: popup)
    }
}
