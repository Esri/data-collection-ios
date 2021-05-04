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
        
        let floatingPanelVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                guard let self = self else { return }
                // If we're showing a floating panel...
                if visible {
                    self.floatingPanelController?.view.alpha = 1.0
                }
                else {
                    // Dismiss the floating panel controller.
                    self.floatingPanelController?.view.alpha = 0.0
                    self.dismissFloatingPanel()
                }
            }
        }

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
                           floatingPanelVisible(false),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            
        case .disabled:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           floatingPanelVisible(false),
                           mapViewVisible(false) ]
            hideMapMaskViewForOfflineDownloadArea()
            
        case .selectingFeature:
            pinDropView.pinDropped = true
            animations = [ selectViewVisible(true),
                           floatingPanelVisible(false),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            selectViewHeaderLabel.text = "Choose location"
            selectViewSubheaderLabel.text = "Pan & zoom map under pin"
            
        case .selectedFeature(let visible):
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           floatingPanelVisible(visible),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            if visible {
                instantiateFloatingPanelForIdentifyResults()
            }
            
        case .editNewFeature:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           floatingPanelVisible(true),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            instantiateFloatingPanelForNewFeature()

        case .offlineMask:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(true),
                           floatingPanelVisible(false),
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

    func instantiateFloatingPanelForIdentifyResults() {
        // If we're showing a floating panel...
        if identifyResultsViewController == nil {
            let bundle = Bundle(for: IdentifyResultsViewController.self)
            let storyboard = UIStoryboard(name: "IdentifyResultsViewController", bundle: bundle)
            identifyResultsViewController = storyboard.instantiateInitialViewController() as? IdentifyResultsViewController
        }
        
        guard let identifyResultsVC = identifyResultsViewController else { return }
        
        // Set the selected popups on the identify results view controller.
        identifyResultsVC.selectedPopups = selectedPopups
        identifyResultsVC.popupChangedHandler = { [weak self] (richPopup: RichPopup?) in
            if let popup = richPopup {
                self?.setCurrentPopup(popup: popup)
                return self?.currentPopupManager
            }
            else {
                self?.setSelectedPopups(popups: identifyResultsVC.selectedPopups)
                return nil
            }
        }

        presentInFloatingPanel(identifyResultsVC, regularWidthInsets: adjustedFloatingPanelInsets())
        floatingPanelController?.view.alpha = 0.0
        floatingPanelController?.transitionDirection = .horizontal
        floatingPanelController?.view.layoutIfNeeded()
    }

    func instantiateFloatingPanelForNewFeature() {
        let bundle = Bundle(for: RichPopupViewController.self)
        let storyboard = UIStoryboard(name: "RichPopup", bundle: bundle)
        if let richPopupViewController = storyboard.instantiateViewController(withIdentifier: "RichPopupViewController") as? RichPopupViewController {
            richPopupViewController.popupManager = currentPopupManager!
            richPopupViewController.setEditing(true, animated: false)
            adjustUIForEditing(true)

            subscribeToEditingPublishers(richPopupViewController)
            
            presentInFloatingPanel(richPopupViewController)

            floatingPanelController?.view.alpha = 0.0
            floatingPanelController?.transitionDirection = .horizontal
            floatingPanelController?.view.layoutIfNeeded()
        }
    }
}
