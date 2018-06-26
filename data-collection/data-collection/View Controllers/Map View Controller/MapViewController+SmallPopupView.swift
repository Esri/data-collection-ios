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

extension MapViewController {
    
    func updateSmallPopupViewForCurrentPopup() {
        
        guard recordsManager != nil else {
            
            mapViewMode = .defaultView
            
            relatedRecordHeaderLabel.text = nil
            relatedRecordSubheaderLabel.text = nil
            relatedRecordsNLabel.text = nil
            
            return
        }
        
        currentPopup!.select()
        
        recordsManager!.loadRelatedRecords { [weak self] in
            
            var fallbackIndex = 0
            
            let fallbackPopupManager = self?.currentPopup?.asManager
            
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
            
            self?.addPopupRelatedRecordButton.isHidden = false
            
            if let canAdd = self?.oneToManyRelatedRecordTable?.canAddFeature {
                self?.addPopupRelatedRecordButton.isHidden = !canAdd
            }
            
            self?.mapViewMode = .selectedFeature
        }
    }
}
