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

/// Represents and manages the one-to-many related records of a popup.
class OneToManyManager: RelatedRecordsManager {
    
    internal private(set) var relatedPopups = [AGSPopup]()
    
    /// Call the super class load function and maintain a reference to the results.
    ///
    /// - Parameter completion: a closure containing an error, if there is one.
    ///
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
            
            // Hold on to the related popupss.
            self?.relatedPopups = popups
            
            // Finally, sort the one-to-many related records.
            self?.sortRelatedRecords()
            
            completion(nil)
        }
    }
    
    /// Relate a new one-to-many record to the managed one.
    func editRelatedPopup(_ editedRelatedPopup: AGSPopup) throws {
        
        guard
            let feature = popup?.geoElement as? AGSArcGISFeature,
            let relatedFeature = editedRelatedPopup.geoElement as? AGSArcGISFeature,
            let info = relationshipInfo
            else {
                throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        // Relate the two records.
        feature.relate(to: relatedFeature, relationshipInfo: info)
        
        // Maintain a reference to the new related record.
        if !relatedPopups.contains(editedRelatedPopup) {
            relatedPopups.append(editedRelatedPopup)
        }
        
        // Sort all related records.
        sortRelatedRecords()
    }
    
    /// Unrelate a one-to-many record from the managed one.
    func deleteRelatedPopup(_ removedRelatedPopup: AGSPopup) throws {
        
        guard
            let feature = popup?.geoElement as? AGSArcGISFeature,
            let relatedFeature = removedRelatedPopup.geoElement as? AGSArcGISFeature,
            let relatedFeatureID = relatedFeature.objectID
            else {
                throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        // Unrelate the two records
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
        
        // Remove the reference to the unrelated record.
        relatedPopups.remove(at: popupIndex)
    }
    
    /// Sort the one-to-many records in descending order.
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
    
    /// Provide the popup for an index path.
    ///
    /// - Parameter indexPath: The index path of the pop-up in question.
    ///
    /// - Returns: A pop-up, if there is one.
    ///
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
