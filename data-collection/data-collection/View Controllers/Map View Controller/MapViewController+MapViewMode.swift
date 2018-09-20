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
        
        if let from = from, from == to {
            return
        }
        
        let smallPopViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                self?.smallPopupView.alpha = CGFloat(visible)
                self?.featureDetailViewBottomConstraint.constant = visible ? 8 : 28
            }
        }
        
        let selectViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                self?.selectView.alpha = CGFloat(visible)
                guard let selectViewHeight = self?.selectView.frame.height else {
                    return
                }
                self?.selectViewTopConstraint.constant = visible ? 0 : -selectViewHeight
            }
        }
        
        let mapViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                self?.mapView.alpha = visible ? 1.0 : 0.0
            }
        }
        
        let animations: [UIViewAnimations]
        
        switch to {
            
        case .defaultView:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           smallPopViewVisible(false),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()

        case .disabled:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           smallPopViewVisible(false),
                           mapViewVisible(false) ]
            hideMapMaskViewForOfflineDownloadArea()
            
        case .selectingFeature:
            pinDropView.pinDropped = true
            animations = [ selectViewVisible(true),
                           smallPopViewVisible(false),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            locationSelectionType = .newFeature
            
        case .selectedFeature:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(false),
                           smallPopViewVisible(true),
                           mapViewVisible(true) ]
            hideMapMaskViewForOfflineDownloadArea()
            
        case .offlineMask:
            pinDropView.pinDropped = false
            animations = [ selectViewVisible(true),
                           smallPopViewVisible(false),
                           mapViewVisible(true) ]
            presentMapMaskViewForOfflineDownloadArea()
            locationSelectionType = .offlineExtent
        }
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            for animation in animations { animation() }
            self?.view.layoutIfNeeded()
        }
    }
}
