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

/// Behavior specific to the _Trees of Portland_ web map.
///
/// When creating or updating an inspection, this function is used to update the symbology of the parent tree
/// according to which inspection's date is newest.
///
/// - Param:
///     - treeManager: The tree's manager object.
///     - completion: The callback called upon completion. The operation is successful or fails, silently.

func updateSymbology(withTreeManager treeManager: PopupRelatedRecordsManager, completion: @escaping () -> Void) {
    
    // This function will be called only after the inspections array has been sorted by inspection date

    // First, find the tree's inspection manager.
    guard let inspectionsManager = treeManager.oneToMany.first(where: { (manager) -> Bool in manager.name == "Inspections" }) else {
        print("[Error: Update Symbology] could not find inspections manager.")
        completion()
        return
    }
    
    let conditionKey = "Condition"
    let dbhKey = "DBH"
    
    // Next, ensure the tree record can update.
    guard
        let treeFeature = treeManager.popup.geoElement as? AGSArcGISFeature,
        let treeFeatureTable = treeFeature.featureTable as? AGSArcGISFeatureTable,
        treeFeatureTable.canUpdate(treeFeature),
        treeFeatureTable.tableName == "Trees",
        treeFeature.attributes[conditionKey] != nil,
        treeFeature.attributes[dbhKey] != nil
        else {
        print("[Error: Update Symbology] tree feature not configured properly.")
        completion()
        return
    }
    
    // Then, find the newest inspection.
    if let newestInspection = inspectionsManager.relatedPopups.first,
        let newestInspectionFeature = newestInspection.geoElement as? AGSArcGISFeature,
        let newestInspectionFeatureTable = newestInspectionFeature.featureTable as? AGSArcGISFeatureTable,
        newestInspectionFeatureTable.tableName == "Inspections",
        newestInspectionFeature.attributes[conditionKey] != nil,
        newestInspectionFeature.attributes[dbhKey] != nil {
         // Update the condtion and dbh of the tree reflecting those of the newest inspection.
        treeFeature.attributes[conditionKey] = newestInspectionFeature.attributes[conditionKey]
        treeFeature.attributes[dbhKey] = newestInspectionFeature.attributes[dbhKey]
    }
    // Unless there is no newest inspection.
    else {
         // Update the condtion and dbh of the tree to reflect a missing inspection.
        treeFeature.attributes[conditionKey] = NSNull()
        treeFeature.attributes[dbhKey] = NSNull()
    }
    
    // Finally, persist the change to the table.
    treeFeatureTable.performEdit(feature: treeFeature) { (error) in
        
        if let error = error {
            print("[Error: Update Symbology]", error.localizedDescription)
        }
        
        completion()
    }
}

extension RelatedRecordsPopupsViewController {
    
    /// Facilitates enacting the custom symbology behavior.
    func checkIfShouldPerformCustomBehavior(_ completion: @escaping () -> Void) {
        
        if shouldEnactCustomBehavior {
            
            let isTreeManager: (PopupRelatedRecordsManager) -> Bool = { manager in
                return manager.tableName == "Trees"
            }
            
            if isTreeManager(recordsManager) {
                updateSymbology(withTreeManager: recordsManager) { completion() }
            }
            else if let parentManager = parentRecordsManager, isTreeManager(parentManager) {
                updateSymbology(withTreeManager: parentManager) { completion() }
            }
            else {
                completion()
            }
        }
        else {
            completion()
        }
    }
}
