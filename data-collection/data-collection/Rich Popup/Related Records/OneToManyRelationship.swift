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
class OneToManyRelationship: Relationship {
    
    internal private(set) var relatedPopups = [AGSPopup]()
    
    // Overrides the superclass method, stores a references to the records.
    override func processRecords(_ popups: [AGSPopup]) {
        
        // Hold on to the related popupss.
        relatedPopups = popups
        
        // Finally, sort the one-to-many related records.
        sortRelatedRecords()
    }

    override func editRelatedPopup(_ editedRelatedPopup: AGSPopup) {
        
        // Maintain a reference to the new related record.
        
        if !relatedPopups.contains(where: { (popup) -> Bool in
            return (popup.geoElement as? AGSArcGISFeature)?.objectID == (editedRelatedPopup.geoElement as? AGSArcGISFeature)?.objectID
        }) {
            relatedPopups.append(editedRelatedPopup)
        }
        
        // Sort all related records.
        sortRelatedRecords()
    }

    override func removeRelatedPopup(_ removedRelatedPopup: AGSPopup) {
        
        let recordIndex = relatedPopups.firstIndex { (popup) -> Bool in
            return (popup.geoElement as? AGSArcGISFeature)?.objectID == (removedRelatedPopup.geoElement as? AGSArcGISFeature)?.objectID
        }
        
        if let index = recordIndex {
            relatedPopups.remove(at: index)
        }
    }
    
    /// Sort the one-to-many records in descending order.
    ///
    private func sortRelatedRecords() {
        do {
            try relatedPopups.sortPopupsByFirstField(.descending)
        }
        catch {
            print("[Error: Sorting AGSPopup]", error.localizedDescription)
        }
    }
}

extension OneToManyRelationship {
    
    /// Provide the popup for an index path.
    ///
    /// - Parameter indexPath: The index path of the pop-up in question.
    ///
    /// - Returns: A pop-up, if there is one.
    ///
    func popup(forIndexPath indexPath: IndexPath) -> AGSPopup? {
        
        // Add an extra row at the top to add feature if that table permits it.
        var rowOffset = 0
        
        if canAddRecord {
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
