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

class OneToManyManager: RelatedRecordsManager {
    
    internal private(set) var relatedPopups = [AGSPopup]()
    
    func load(records completion: @escaping (Error?) -> Void) {
        
        super.load { [weak self] (popupsResults, error) in
            
            if let err = error {
                completion(err)
                return
            }
            
            guard let popups = popupsResults else {
                completion(FeatureTableError.queryResultsMissingPopups)
                return
            }
            
            self?.relatedPopups = popups
            
            self?.sortRelatedRecords()
            
            completion(nil)
        }
    }
    
    func editRelatedPopup(_ editedRelatedPopup: AGSPopup) throws {
        
        guard
            let feature = popup?.geoElement as? AGSArcGISFeature,
            let relatedFeature = editedRelatedPopup.geoElement as? AGSArcGISFeature,
            let info = relationshipInfo
            else {
                throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        feature.relate(to: relatedFeature, relationshipInfo: info)
        
        if !relatedPopups.contains(editedRelatedPopup) {
            relatedPopups.append(editedRelatedPopup)
        }
        
        sortRelatedRecords()
    }
    
    
    
    func deleteRelatedPopup(_ removedRelatedPopup: AGSPopup) throws {
        
        guard
            let feature = popup?.geoElement as? AGSArcGISFeature,
            let relatedFeature = removedRelatedPopup.geoElement as? AGSArcGISFeature,
            let relatedFeatureID = relatedFeature.objectID
            else {
                throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        feature.unrelate(to: relatedFeature)
        
        let foundPopupIndex = relatedPopups.index { (popup) -> Bool in
            
            guard
                let feature = popup.geoElement as? AGSArcGISFeature,
                let oid = feature.objectID
                else {
                    return false
            }
            
            return oid == relatedFeatureID
        }
        
        guard let popupIndex = foundPopupIndex else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        relatedPopups.remove(at: popupIndex)
    }
    
    private func sortRelatedRecords() {
        do {
            try relatedPopups.sortPopupsByFirstField(.descending)
        }
        catch {
            print("[Error: Sorting AGSPopup]", error.localizedDescription)
        }
    }
}

extension OneToManyManager {
    
    func popup(forIndexPath indexPath: IndexPath) -> AGSPopup? {
        
        // Add an extra row at the top to add feature if that table permits it.
        var rowOffset = 0
        if let table = relatedTable, table.canAddFeature {
            rowOffset += 1
        }
        
        // Determine which One To Many record we'd like to display
        let rowIndex = indexPath.row - rowOffset
        
        // Add feature row button
        if indexPath.row < rowOffset {
            return nil
        }
        // Display popup at index
        else {
            return relatedPopups[rowIndex]
        }
    }
}
