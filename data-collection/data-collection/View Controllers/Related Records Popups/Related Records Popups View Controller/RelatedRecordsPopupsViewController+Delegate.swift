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

extension RelatedRecordsPopupsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {

        return !indexPathWithinAttributes(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard !indexPathWithinAttributes(indexPath) else {
            return
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) as? RelatedRecordCell, let childPopup = cell.popup else {
            return
        }
        
        if indexPath.section == 0, recordsManager.isEditing {
            EphemeralCache.set(object: childPopup, forKey: RelatedRecordsPopupsViewController.ephemeralCacheKey)
            performSegue(withIdentifier: "selectRelatedRecordSegue", sender: self)
        }
            
        else if recordsManager.isEditing {
            // TODO Alert!
            self.present(simpleAlertMessage: "You must save first!")
            // TODO (Save & Present) or (Cancel)
            return
        }
        else if let rrvc = storyboard?.instantiateViewController(withIdentifier: "RelatedRecordsPopupsViewController") as? RelatedRecordsPopupsViewController {
            rrvc.popup = childPopup
            rrvc.parentPopup = self.popup
            self.navigationController?.pushViewController(rrvc, animated: true )
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        guard section == 0, loadingRelatedRecords else {
            return 0.0
        }
        
        return 35.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard section == 0, loadingRelatedRecords else {
            return nil
        }
        
        let containerHeight: CGFloat = 35.0
        let container = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.size.width, height: containerHeight))
        container.backgroundColor = .clear
        
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activity.startAnimating()
        
        container.addSubview(activity)
        activity.center = container.convert(container.center, from:container.superview)
        return container
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // TODO NO ACTIONS FOR NON EDITABLE ROWS
        
        guard indexPath.section > 0 else {
            return nil
        }
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit") { [weak self] (action, indexPath) in
            
            // TODO MUST SAVE CURRENT POPUP FIRST
            print("Will Edit Inspection")

            let editPopupClosure: () -> Void = { [weak self] in
                
                guard
                    let cell = tableView.cellForRow(at: indexPath) as? RelatedRecordCell,
                    let childPopup = cell.popup,
                    let rrvc = self?.storyboard?.instantiateViewController(withIdentifier: "RelatedRecordsPopupsViewController") as? RelatedRecordsPopupsViewController
                    else {
                        // TODO inform user
                        return
                }
                
                rrvc.popup = childPopup
                rrvc.parentPopup = self?.popup
                rrvc.editingPopup = true
                
                self?.navigationController?.pushViewController(rrvc, animated: true)
            }

            editPopupClosure()
        }
        
        editAction.backgroundColor = .orange
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete") { [weak self] (action, indexPath) in
            
            // TODO MUST SAVE CURRENT POPUP FIRST
            print("Will Delete Inspection")
            
            let deletePopupClosure: () -> Void = { [weak self] in
                
            }
            
            deletePopupClosure()
        }
        deleteAction.backgroundColor = .red
        
        return [deleteAction, editAction]
    }
    
    func indexPathWithinAttributes(_ indexPath: IndexPath) -> Bool {
        
        guard indexPath.section == 0 else {
            return false
        }
        
        let nFields = recordsManager.isEditing ? recordsManager.editableDisplayFields.count : recordsManager.displayFields.count
        
        return indexPath.row < nFields
    }
}
