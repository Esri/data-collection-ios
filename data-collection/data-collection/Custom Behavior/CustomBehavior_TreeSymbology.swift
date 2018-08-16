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

func updateSymbology(withTreeManager treeManager: PopupRelatedRecordsManager, completion: @escaping () -> Void) {
    
    // This function will be called only after the inspections array has been sorted by inspection date

    var foundInspectionsManager: OneToManyManager?
    
    for manager in treeManager.oneToMany {
        
        if let name = manager.name, name == "Inspections" {
            foundInspectionsManager = manager
            break
        }
    }
    
    guard let inspectionsManager = foundInspectionsManager else {
        print("[Error: Update Symbology] could not find inspections manager.")
        completion()
        return
    }
    
    guard
        let treeFeature = treeManager.popup.geoElement as? AGSArcGISFeature,
        let treeFeatureTable = treeFeature.featureTable as? AGSArcGISFeatureTable,
        treeFeatureTable.canUpdate(treeFeature),
        treeFeatureTable.tableName == "Trees"
        else {
        print("[Error: Update Symbology] could not find tree table or update tree.")
        completion()
        return
    }
    
    guard
        let newestInspection = inspectionsManager.relatedPopups.first,
        let newestInspectionFeature = newestInspection.geoElement as? AGSArcGISFeature,
        let newestInspectionFeatureTable = newestInspectionFeature.featureTable as? AGSArcGISFeatureTable,
        newestInspectionFeatureTable.tableName == "Inspections"
        else {
            print("[Error: Update Symbology] could not find inspections table.")
            completion()
            return
    }
    
    let conditionKey = "Condition"
    let dbhKey = "DBH"
    
    guard
        let treeKeys = treeFeature.attributes.allKeys as? [String],
        treeKeys.contains(conditionKey),
        treeKeys.contains(dbhKey)
        else {
            print("[Error: Update Symbology] tree attributes doensn't contain condition or dbh keys.")
        completion()
            return
    }
    
    guard
        let inspectionKeys = newestInspectionFeature.attributes.allKeys as? [String],
        inspectionKeys.contains(conditionKey),
        inspectionKeys.contains(dbhKey)
        else {
            print("[Error: Update Symbology] inspection attributes doensn't contain condition or dbh keys.")
            completion()
            return
    }
    
    treeFeature.attributes[conditionKey] = newestInspectionFeature.attributes[conditionKey]
    treeFeature.attributes[dbhKey] = newestInspectionFeature.attributes[dbhKey]
    
    treeFeatureTable.performEdit(feature: treeFeature) { (error) in
        
        if let error = error {
            print("[Error: Update Symbology]", error.localizedDescription)
        }
        
        completion()
    }
}

extension RelatedRecordsPopupsViewController {
    
    func customTreeBehavior(_ completion: @escaping () -> Void) {
        
        if shouldEnactCustomBehavior {
            
            let isTreeManager: (PopupRelatedRecordsManager) -> Bool = { manager in
                guard let tableName = manager.tableName else {
                    return false
                }
                return tableName == "Trees"
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
