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
    
    @objc private func userDidTouchDragSmallPopupView(_ sender: Any) {
        guard case MapViewMode.selectedFeature(featureLoaded: true) = mapViewMode, let shrinkingView = sender as? ShrinkingView else { return }
        featureDetailViewBottomConstraint.constant = shrinkingView.yDelta + 8
    }
    
    @objc private func userDidTapSmallPopupView(_ sender: Any) {
        guard case MapViewMode.selectedFeature(featureLoaded: true) = mapViewMode, currentPopupManager != nil else { return }
        mapViewMode = .selectedFeature(featureLoaded: true)
        performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
    }
    
    @objc private func userDidDismissSmallPopupView(_ sender: Any) {
        guard case MapViewMode.selectedFeature(true) = mapViewMode else { return }
        self.clearCurrentPopup()
        self.mapViewMode = .defaultView
    }
    
    @objc private func resetSmallPopupViewAfterTouchEvent(_ sender: Any) {
        guard case MapViewMode.selectedFeature(featureLoaded: true) = mapViewMode else { return }
        mapViewMode = .selectedFeature(featureLoaded: true)
    }
    
    func setupSmallPopupView() {
        smallPopupView.addTarget(self, action: #selector(MapViewController.userDidTapSmallPopupView), for: .touchUpInside)
        smallPopupView.addTarget(self, action: #selector(MapViewController.resetSmallPopupViewAfterTouchEvent), for: .touchUpOutside)
        smallPopupView.addTarget(self, action: #selector(MapViewController.resetSmallPopupViewAfterTouchEvent), for: .touchCancel)
        smallPopupView.addTarget(self, action: #selector(MapViewController.userDidTouchDragSmallPopupView), for: .touchDragInside)
        smallPopupView.addTarget(self, action: #selector(MapViewController.userDidDismissSmallPopupView), for: .touchDragExit)
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
            (feature.featureTable?.layer as? AGSFeatureLayer)?.select(feature)
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
            
            relatedRecordHeaderLabel.text = (manyToOneAttributes.popFirst() ?? backupAttributes.popFirst())?.value
            relatedRecordSubheaderLabel.text = (manyToOneAttributes.popFirst() ?? backupAttributes.popFirst())?.value
        }
        else {
            
            relatedRecordHeaderLabel.text = backupAttributes.popFirst()?.value
            relatedRecordSubheaderLabel.text = backupAttributes.popFirst()?.value
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
            
            relatedRecordsNLabel.text = backupAttributes.popFirst()?.value
            addPopupRelatedRecordButton.isHidden = true
        }
        
        mapViewMode = .selectedFeature(featureLoaded: true)
    }
}

private extension Array {
    
    mutating func popFirst() -> Element? {
        if !isEmpty {
            return removeFirst()
        } else {
            return nil
        }
    }
}
