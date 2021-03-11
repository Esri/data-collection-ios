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

extension MapViewController {
    
    func adjustForMapViewMode(from: MapViewMode?, to: MapViewMode) {
        
        let identifyResultsVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                guard let self = self else { return }
                // If we're showing a floating panel...
                if visible {
                    // Set the selected popups on the identify results view controller.
                    self.identifyResultsViewController.selectedPopups = self.selectedPopups
                    self.identifyResultsViewController.popupChangedHandler = { [weak self] (richPopup: RichPopup?) in
                        // Use the geometry engine to determine the nearest pop-up to the touch point.
                        if let popup = richPopup {
                            self?.setCurrentPopup(popup: popup)
                        }
                        else {
                            self?.clearCurrentPopup()
                        }
                    }
                    let floatingPanelItem = self.identifyResultsViewController.floatingPanelItem
                    floatingPanelItem.title = "Identify Results"
                    
                    let selected = self.selectedPopups.count
                    floatingPanelItem.subtitle = String("\(selected) Feature\(selected > 1 ? "s" : "")")
                    floatingPanelItem.image = UIImage(named: "feature-details")
                    self.presentInFloatingPanel(self.identifyResultsViewController)
                    self.floatingPanelController?.delegate = self
                }
                else {
                    // Dismiss the floating panel controller.
                    self.dismissFloatingPanel()
                }
            }
        }
        
        //        let smallPopViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
        //            return {
        //                guard let self = self else { return }
        //                self.smallPopupView.alpha = CGFloat(visible)
        //                self.featureDetailViewBottomConstraint.constant = visible ? 8 : -156
        //            }
        //        }
        
        let selectViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                guard let self = self else { return }
                self.selectView.alpha = CGFloat(visible)
                self.selectViewTopConstraint.isActive = visible
            }
        }
        
        let mapViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                guard let self = self else { return }
                self.mapView.alpha = CGFloat(visible)
            }
        }
        
        let animations: [UIViewAnimations]
        
        switch to {
        
        case .defaultView:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           identifyResultsVisible(false),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            
        case .disabled:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           identifyResultsVisible(false),
                           mapViewVisible(false) ]
            hideMapMaskViewForOfflineDownloadArea()
            
        case .selectingFeature:
            pinDropView.pinDropped = true
            animations = [ selectViewVisible(true),
                           identifyResultsVisible(false),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            selectViewHeaderLabel.text = "Choose location"
            selectViewSubheaderLabel.text = "Pan & zoom map under pin"
            
        case .selectedFeature(let visible):
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           identifyResultsVisible(visible),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            
        case .offlineMask:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(true),
                           identifyResultsVisible(false),
                           mapViewVisible(true) ]
            presentMapMaskViewForOfflineDownloadArea()
            selectViewHeaderLabel.text = "Choose extent"
            selectViewSubheaderLabel.text = "Pan & zoom map within region"
        }
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            for animation in animations { animation() }
            self?.view.layoutIfNeeded()
        }
    }
}
