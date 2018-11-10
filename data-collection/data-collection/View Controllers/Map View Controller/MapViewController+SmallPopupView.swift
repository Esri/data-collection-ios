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
    
    @objc func didTapSmallPopupView(_ sender: Any) {
        guard currentPopup != nil else { return }
        performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
    }
    
    func refreshCurrentPopup() {
        
        guard case MapViewMode.selectedFeature = mapViewMode, let popup = currentPopup else {
            return
        }
        
        guard popup.isFeatureAddedToTable else {
            currentPopup = nil
            mapViewMode = .defaultView
            return
        }
        
        popup.select()
        
        let populateContentIntoSmallPopupView: () -> Void = {
            
            var fallbackIndex = 0
            
            let fallbackPopupManager = popup.asManager()
            
            if let manyToOneManager = popup.relationships?.manyToOne.first?.relatedPopup?.asManager() {
                var destinationIndex = 0
                self.relatedRecordHeaderLabel.text = manyToOneManager.nextDisplayFieldStringValue(fieldIndex: &destinationIndex) ?? fallbackPopupManager.nextDisplayFieldStringValue(fieldIndex: &fallbackIndex)
                self.relatedRecordSubheaderLabel.text = manyToOneManager.nextDisplayFieldStringValue(fieldIndex: &destinationIndex) ?? fallbackPopupManager.nextDisplayFieldStringValue(fieldIndex: &fallbackIndex)
            }
            else {
                self.relatedRecordHeaderLabel.text = fallbackPopupManager.nextDisplayFieldStringValue(fieldIndex: &fallbackIndex)
                self.relatedRecordSubheaderLabel.text = fallbackPopupManager.nextDisplayFieldStringValue(fieldIndex: &fallbackIndex)
            }
            
            if let oneToMany = popup.relationships?.oneToMany.first {
                let n = oneToMany.relatedPopups.count
                let name = oneToMany.relatedTable?.tableName ?? "Records"
                self.relatedRecordsNLabel.text = "\(n) \(name)"
            }
            else {
                self.relatedRecordsNLabel.text = fallbackPopupManager.nextDisplayFieldStringValue(fieldIndex: &fallbackIndex)
            }
            
            if let canAdd = popup.relationships?.oneToMany.first?.relatedTable?.canAddFeature {
                self.addPopupRelatedRecordButton.isHidden = !canAdd
            }
            else {
                self.addPopupRelatedRecordButton.isHidden = true
            }
            
            self.mapViewMode = .selectedFeature(featureLoaded: true)
        }
        
        if let popupRelationships = popup.relationships {
            
            popupRelationships.load { (error) in
                
                if let error = error {
                    print("[Error: RichPopup] relationships load error: \(error)")
                }
                
                populateContentIntoSmallPopupView()
            }
        }
        else {
            
            populateContentIntoSmallPopupView()
        }
    }
}
