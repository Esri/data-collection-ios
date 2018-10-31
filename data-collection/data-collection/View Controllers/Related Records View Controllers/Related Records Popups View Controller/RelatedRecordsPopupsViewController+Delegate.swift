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

extension RelatedRecordsPopupsViewController {
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {

        // We only want to highlight related records
        return !recordsManager.indexPathWithinAttributes(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        // Wants to delete record
        if selectedCell is DeleteRecordCell {
            
            deletePopupAndDismissViewController()
            return
        }
        
        // Any other action should only want to allow selection of related records
        guard let cell = selectedCell as? RelatedRecordCell else { return }
        
        // Should edit M:1 Related Record
        if indexPath.section == 0, recordsManager.isEditing {
            
            guard let table = cell.table else { return }
            
            EphemeralCache.set(object: table, forKey: EphemeralCacheKeys.tableList)
            performSegue(withIdentifier: "selectRelatedRecordSegue", sender: self)
            
            return
        }
        
        // Should edit existing 1:M Related Record
        if indexPath.section > 0, let childPopup = cell.popup, recordsManager.isEditing {
            
            closeEditingSessionAndBeginEditing(childPopup: childPopup)
            
            return
        }
        
        // Should add new 1:M Related Record
        if indexPath.section > 0, cell.popup == nil {
            
            guard let table = cell.table, table.canAddFeature, let newPopup = table.createPopup() else {
                present(simpleAlertMessage: "An unknown error occurred!")
                return
            }
            
            closeEditingSessionAndBeginEditing(childPopup: newPopup)
            
            return
        }
        
        // Requesting view popup
        if let rrvc = storyboard?.instantiateViewController(withIdentifier: "RelatedRecordsPopupsViewController") as? RelatedRecordsPopupsViewController, let childPopup = cell.popup, let parentRecordsManager = recordsManager {
            
            rrvc.popup = childPopup
            rrvc.parentRecordsManager = parentRecordsManager
            show(rrvc, sender: self)
            
            return
        }
    }
    
    fileprivate var activityIndicatorViewHeight: CGFloat { return 35.0 }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            return loadingRelatedRecords ? activityIndicatorViewHeight : 0.0
        }
        else {
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // If the view controller is loading related records, we want to add an activity indicator view in the table view's header.
        guard section == 0, loadingRelatedRecords else {
            return nil
        }
        
        let container = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.width, height: activityIndicatorViewHeight))
        container.backgroundColor = .clear
        
        let activity = UIActivityIndicatorView(style: .gray)
        activity.accessibilityLabel = "Loading Related Records"
        activity.startAnimating()
        
        container.addSubview(activity)
        activity.center = container.convert(container.center, from:container.superview)
        return container
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // We don't want to offer edit row actions to pop-up fields.
        guard
            recordsManager.indexPathWithinOneToMany(indexPath),
            let cell = tableView.cellForRow(at: indexPath) as? RelatedRecordCell,
            let childPopup = cell.popup
            else {
            return nil
        }
        
        var actions = [UITableViewRowAction]()
        
        // Add an edit action, if editable.
        if childPopup.isEditable {
            let editAction = UITableViewRowAction(style: .default, title: "Edit") { [weak self] (action, indexPath) in
                self?.closeEditingSessionAndBeginEditing(childPopup: childPopup)
            }
            
            editAction.backgroundColor = .tableCellEditAction
            actions.append(editAction)
        }

        // Add delete action, if can delete.
        if let feature = childPopup.geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable, featureTable.canDelete(feature) {
            let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { [weak self] (action, indexPath) in
                self?.present(confirmationAlertMessage: "Are you sure you want to delete this \(childPopup.title ?? "record")?", confirmationTitle: "Delete", confirmationAction: { [weak self] (_) in
                    self?.closeEditingSessionAndDelete(childPopup: childPopup)
                })
            }
            
            deleteAction.backgroundColor = .tableCellDeleteAction
            actions.append(deleteAction)
        }
        
        return actions.count > 0 ? actions : nil
    }
}
