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

        // We only want to highlight related records
        return !recordsManager.indexPathWithinAttributes(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Wants to delete record
        if let _ = tableView.cellForRow(at: indexPath) as? DeleteRecordCell {
            guard appContext.isLoggedIn else {
                present(loginAlertMessage: "You must log in to delete this record.")
                return
            }
            print("wants to delete")
            return
        }
        
        // Any other action should only want to allow selection of related records
        guard let cell = tableView.cellForRow(at: indexPath) as? RelatedRecordCell else {
            return
        }
        
        // Should edit M:1 Related Record
        if indexPath.section == 0, recordsManager.isEditing {
            
            guard let table = cell.table else { return }
            
            EphemeralCache.set(object: table, forKey: EphemeralCacheKeys.tableList)
            performSegue(withIdentifier: "selectRelatedRecordSegue", sender: self)
            
            return
        }
        
        // Should edit existing 1:M Related Record
        if indexPath.section > 0, let childPopup = cell.popup, recordsManager.isEditing {
            
            guard appContext.isLoggedIn else {
                present(loginAlertMessage: "You must log in to make edits.")
                return
            }
            
            closeEditingSessionAndBeginEditing(childPopup: childPopup)
            
            return
        }
        
        // Should add new 1:M Related Record
        if indexPath.section > 0, cell.popup == nil {
            
            guard appContext.isLoggedIn else {
                present(loginAlertMessage: "You must log in to make edits.")
                return
            }
            
            guard let table = cell.table, table.canAddFeature, let popupDefinition = table.popupDefinition else {
                present(simpleAlertMessage: "An unknown error occurred!")
                return
            }
            
            let newFeature = table.createFeature()
            let newPopup = AGSPopup(geoElement: newFeature, popupDefinition: popupDefinition)
            
            closeEditingSessionAndBeginEditing(childPopup: newPopup)
            
            return
        }
        
        // Requesting view popup
        if let rrvc = storyboard?.instantiateViewController(withIdentifier: "RelatedRecordsPopupsViewController") as? RelatedRecordsPopupsViewController, let childPopup = cell.popup, let parentRecordsManager = recordsManager {
            
            rrvc.popup = childPopup
            rrvc.parentPopupManager = parentRecordsManager
            self.navigationController?.pushViewController(rrvc, animated: true)
            
            return
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
        
        guard
            recordsManager.indexPathWithinOneToMany(indexPath),
            let cell = tableView.cellForRow(at: indexPath) as? RelatedRecordCell,
            let relationshipInfo = cell.relationshipInfo,
            let childPopup = cell.popup
            else {
            return nil
        }
        
        var actions = [UITableViewRowAction]()
        
        if childPopup.isEditable {
            let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit") { [weak self] (action, indexPath) in
                self?.closeEditingSessionAndBeginEditing(childPopup: childPopup)
            }
            
            editAction.backgroundColor = .orange
            actions.append(editAction)
        }

        if let feature = childPopup.geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable, featureTable.canDelete(feature) {
            let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete") { [weak self] (action, indexPath) in
                self?.present(confirmationAlertMessage: "Are you sure you want to delete this \(childPopup.title ?? "record")?", confirmationTitle: "Delete", confirmationAction: { [weak self] (_) in
                    self?.closeEditingSessionAndDelete(childPopup: childPopup, forRelationshipInfo: relationshipInfo)
                })
            }
            
            deleteAction.backgroundColor = .red
            actions.append(deleteAction)
        }
        
        return actions.count > 0 ? actions : nil
    }
}
