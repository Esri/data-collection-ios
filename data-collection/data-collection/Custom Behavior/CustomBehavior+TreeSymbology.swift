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

func updateSymbology(forTreePopup tree: AGSPopup, withNewestInspection manager: PopupRelatedRecordsManager, completion: @escaping () -> Void) {
    
    // This function will have been called only after the inspections array has been sorted by inspection date

    var foundInspectionsManager: OneToManyManager?
    
    for manager in manager.oneToMany {
        
        if let name = manager.name, name == "Inspections" {
            foundInspectionsManager = manager
            break
        }
    }
    
    guard let inspectionsManager = foundInspectionsManager else {
        completion()
        return
    }
    
    guard
        let treeFeature = tree.geoElement as? AGSArcGISFeature,
        let treeFeatureTable = treeFeature.featureTable as? AGSArcGISFeatureTable,
        treeFeatureTable.tableName == "Trees",
        let newestInspection = inspectionsManager.relatedPopups.first,
        let newestInspectionFeature = newestInspection.geoElement as? AGSArcGISFeature,
        let newestInspectionFeatureTable = newestInspectionFeature.featureTable as? AGSArcGISFeatureTable,
        newestInspectionFeatureTable.tableName == "Inspections"
        else {
        completion()
        return
    }
    
    let conditionKey = "Condition"
    let dbhKey = "DBH"
    
    guard
        let treeKeys = treeFeature.attributes.allKeys as? [String],
        treeKeys.contains(conditionKey),
        treeKeys.contains(dbhKey),
        let inspectionKeys = newestInspectionFeature.attributes.allKeys as? [String],
        inspectionKeys.contains(conditionKey),
        inspectionKeys.contains(dbhKey)
        else {
        completion()
            return
    }
    
    treeFeature.attributes[conditionKey] = newestInspectionFeature.attributes[conditionKey]
    treeFeature.attributes[dbhKey] = newestInspectionFeature.attributes[dbhKey]
    
    treeFeatureTable.performEdit(feature: treeFeature) { (error) in
        
        if let error = error {
            print("[Error: Updating Tree]", error.localizedDescription)
        }
        
        completion()
    }
}
