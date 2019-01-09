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
        guard currentPopupManager != nil else { return }
        performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
    }
    
    func refreshCurrentPopup() {
        
        guard case MapViewMode.selectedFeature = mapViewMode, let popup = currentPopupManager?.richPopup else {
            return
        }
        
        guard popup.isFeatureAddedToTable else {
            clearCurrentPopup()
            mapViewMode = .defaultView
            return
        }
        
        // Select the underlying feature
        if let feature = popup.feature {
            feature.featureTable?.featureLayer?.select(feature)
        }
        
        if let popupRelationships = popup.relationships {
            
            popupRelationships.load { [weak self] (error) in
                
                if let error = error {
                    print("[Error: RichPopup] relationships load error: \(error)")
                }
                
                guard let self = self else { return }
                
                self.populateContentIntoSmallPopupView(popup)
            }
        }
        else {
            
            populateContentIntoSmallPopupView(popup)
        }
    }
    
    private func populateContentIntoSmallPopupView(_ popup: RichPopup) {
        
        // Build a backup list of attributes from the top display attributes from the identified pop-up.
        var backupAttributes = AGSPopupManager.generateDisplayAttributes(forPopup: popup, max: 3)
        
        // MARK: Left side of the small pop-up view, concerns the first many-to-one relationship.
        
        if let firstManyToOne = popup.relationships?.manyToOne.first?.relatedPopup {
            
            var manyToOneAttributes = AGSPopupManager.generateDisplayAttributes(forPopup: firstManyToOne, max: 2)
            
            relatedRecordHeaderLabel.text = AGSPopupManager.nextDisplayAttribute(priorityAttributes: &manyToOneAttributes, backupAttributes: &backupAttributes)?.value
            relatedRecordSubheaderLabel.text = AGSPopupManager.nextDisplayAttribute(priorityAttributes: &manyToOneAttributes, backupAttributes: &backupAttributes)?.value
        }
        else {
            
            relatedRecordHeaderLabel.text = AGSPopupManager.nextDisplayAttribute(&backupAttributes)?.value
            relatedRecordSubheaderLabel.text = AGSPopupManager.nextDisplayAttribute(&backupAttributes)?.value
        }
        
        // MARK: Right side of the small pop-up view, concerns the first one-to-many relationship.
        
        if let firstOneToMany = popup.relationships?.oneToMany.first {
            
            let n = firstOneToMany.relatedPopups.count
            let name = firstOneToMany.name ?? "Records"
            let value = "\(n) \(name)"
            
            relatedRecordsNLabel.text = value
            addPopupRelatedRecordButton.isHidden = !firstOneToMany.canAddRecord
        }
        else {
            
            relatedRecordsNLabel.text = AGSPopupManager.nextDisplayAttribute(&backupAttributes)?.value
            addPopupRelatedRecordButton.isHidden = true
        }
        
        mapViewMode = .selectedFeature(featureLoaded: true)
    }
}

private extension AGSPopupManager {
    
    static func nextDisplayAttribute(_ attributes: inout [DisplayAttribute]) -> DisplayAttribute? {
        
        if !attributes.isEmpty {
            return attributes.remove(at: 0)
        }
        else {
            return nil
        }
    }
    
    static func nextDisplayAttribute(priorityAttributes: inout [DisplayAttribute], backupAttributes: inout [DisplayAttribute]) -> DisplayAttribute? {
        
        if !priorityAttributes.isEmpty {
            return priorityAttributes.remove(at: 0)
        }
        else if !backupAttributes.isEmpty {
            return backupAttributes.remove(at: 0)
        }
        else {
            return nil
        }
    }
}
