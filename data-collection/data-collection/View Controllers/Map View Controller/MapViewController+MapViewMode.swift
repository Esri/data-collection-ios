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
        
        func setIdentifyResultsVisible(_ visible: Bool) {
            // If we're showing a floating panel...
            if visible {
                if floatingPanelViewController?.initialViewController == identifyResultsViewController {
                    floatingPanelViewController?.floatingPanelSubtitle = String("\(selectedPopups.count) Features")
                }
                else {
                    showFloatingPanel(identifyResultsViewController,
                                      title: "Identify Results",
                                      subtitle: String("\(selectedPopups.count) Features"),
                                      image: UIImage(named: "feature-details"))
                }
                
                // Set the selected popups on the identify results view controller.
                identifyResultsViewController.selectedPopups = selectedPopups
            }
//            else if let floatingPanelVC = floatingPanelViewController {
//                if floatingPanelVC.initialViewController == identifyResultsViewController {
//                    // Dismiss the floating panel if we're displaying identify results.
//                    dismissFloatingPanel(floatingPanelVC)
//                }
//            }
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
        var identifyResultsVisible = false
        switch to {
            
        case .defaultView:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()

        case .disabled:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           mapViewVisible(false) ]
            hideMapMaskViewForOfflineDownloadArea()
            
        case .selectingFeature:
            pinDropView.pinDropped = true
            animations = [ selectViewVisible(true),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            selectViewHeaderLabel.text = "Choose location"
            selectViewSubheaderLabel.text = "Pan & zoom map under pin"
            
        case .selectedFeature(let loaded):
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           mapViewVisible(true) ]
            identifyResultsVisible = true
            hideMapMaskViewForOfflineDownloadArea()
            
        case .offlineMask:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(true),
                           mapViewVisible(true) ]
            presentMapMaskViewForOfflineDownloadArea()
            selectViewHeaderLabel.text = "Choose extent"
            selectViewSubheaderLabel.text = "Pan & zoom map within region"
        }
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            for animation in animations { animation() }
            self?.view.layoutIfNeeded()
        }) { (finished) in
            setIdentifyResultsVisible(identifyResultsVisible)
        }
    }
}
