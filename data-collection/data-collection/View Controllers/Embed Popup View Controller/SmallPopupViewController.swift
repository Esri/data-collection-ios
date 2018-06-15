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
import UIKit
import ArcGIS

class SmallPopupViewController: AppContextAwareController {
    
    @IBOutlet weak var relatedRecordHeaderLabel: UILabel!
    @IBOutlet weak var relatedRecordSubheaderLabel: UILabel!
    @IBOutlet weak var relatedRecordsNLabel: UILabel!
    
    var popup: AGSPopup? {
        didSet {
            recordsManager = popup != nil ? PopupRelatedRecordsManager(popup: popup!) : nil
        }
    }
    
    internal private(set) var recordsManager: PopupRelatedRecordsManager?
    
    var oneToManyRelatedRecordTable: AGSArcGISFeatureTable? {
        return recordsManager?.oneToMany.first?.relatedTable
    }
    
    /**
     The small popup view controller (spvc) is concerned primarly with displaying content to do with related records.
     Specifically, the spvc is concerned with two related record types.
     1) The (left) side of the spvc concerns itself with displaying content from the highest order related table where the relationship is one to many and the feature of interest is the destination
     2) The (right) side of the spvc concerns itself with displaying content from the highest order related table where the relationship is one to many and the feature of interest is the origin
     Should the feature of interest not contain tables with this specific related table relationships, the spvc populates itself with content derived from itself's feature of interest
     */
    
    func populateWithRelatedRecordContent(_ complete: @escaping () -> Void) {
        
        guard recordsManager != nil else {
            clearLabels()
            complete()
            return
        }
        
        recordsManager!.loadRelatedRecords { [weak self] in
            
            var fallbackIndex = 0
            
            let fallbackPopupManager = self?.popup?.asManager
            
            if let manyToOneManager = self?.recordsManager?.manyToOne.first?.relatedPopup?.asManager {
                
                var destinationIndex = 0
                
                self?.relatedRecordHeaderLabel.text = manyToOneManager.nextFieldStringValue(idx: &destinationIndex) ?? fallbackPopupManager?.nextFieldStringValue(idx: &fallbackIndex)
                self?.relatedRecordSubheaderLabel.text = manyToOneManager.nextFieldStringValue(idx: &destinationIndex) ?? fallbackPopupManager?.nextFieldStringValue(idx: &fallbackIndex)
            }
            else {
                
                self?.relatedRecordHeaderLabel.text = fallbackPopupManager?.nextFieldStringValue(idx: &fallbackIndex)
                self?.relatedRecordSubheaderLabel.text = fallbackPopupManager?.nextFieldStringValue(idx: &fallbackIndex)
            }
            
            if let oneToMany = self?.recordsManager?.oneToMany.first {
                
                let n = oneToMany.relatedPopups.count
                let name = oneToMany.relatedTable?.tableName ?? "Records"
                self?.relatedRecordsNLabel.text = "\(n) \(name)"
            }
            else {
                
                self?.relatedRecordsNLabel.text = fallbackPopupManager?.nextFieldStringValue(idx: &fallbackIndex)
            }
            
            complete()
        }
    }
    
    private func clearLabels() {
        relatedRecordHeaderLabel.text = nil
        relatedRecordSubheaderLabel.text = nil
        relatedRecordsNLabel.text = nil
    }
}
