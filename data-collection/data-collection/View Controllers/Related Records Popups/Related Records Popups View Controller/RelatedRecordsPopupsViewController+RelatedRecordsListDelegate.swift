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

extension RelatedRecordsPopupsViewController: RelatedRecordsListViewControllerDelegate {
    
    func relatedRecordsListViewController(_ viewController: RelatedRecordsListViewController, didSelectPopup relatedPopup: AGSPopup) {
        
        _ = navigationController?.popViewController(animated: true)
        
        guard let info = self.popup.relationship(withPopup: relatedPopup) else {
            present(simpleAlertMessage: "Uh Oh! An unknown error occurred.")
            return
        }
        
        do {
            try recordsManager.update(manyToOne: relatedPopup, forRelationship: info)
        }
        catch {
            print("[Error] couldn't update related record", error.localizedDescription)
            present(simpleAlertMessage: "Uh Oh! You couldn't update the related record.")
        }
        
        tableView.reloadData()
    }
    
    func relatedRecordsListViewControllerDidCancel(_ viewController: RelatedRecordsListViewController) {
        
        _ = navigationController?.popViewController(animated: true)
    }
}
