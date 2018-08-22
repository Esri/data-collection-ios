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

enum MapViewMode {
    case defaultView
    case disabled
    case selectedFeature
    case selectingFeature
    case offlineMask
}

extension MapViewController {
    
    func adjustForMapViewMode(from: MapViewMode?, to: MapViewMode) {
        
        if let from = from, from == to {
            return
        }
        
        let smallPopViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                self?.smallPopupView.alpha = visible.asAlpha
                self?.featureDetailViewBottomConstraint.constant = visible ? 8 : 28
            }
        }
        
        let selectViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                self?.selectView.alpha = visible.asAlpha
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
        
        var animations = [UIViewAnimations]()
        
        switch to {
            
        case .defaultView:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(false) )
            animations.append( mapViewVisible(true) )
            hideMapMaskViewForOfflineDownloadArea()

        case .disabled:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(false) )
            animations.append( mapViewVisible(false) )
            hideMapMaskViewForOfflineDownloadArea()
            
        case .selectingFeature:
            pinDropView.pinDropped = true
            animations.append( selectViewVisible(true) )
            animations.append( smallPopViewVisible(false) )
            animations.append( mapViewVisible(true) )
            hideMapMaskViewForOfflineDownloadArea()
            locationSelectionType = .newFeature
            
        case .selectedFeature:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(true) )
            animations.append( mapViewVisible(true) )
            hideMapMaskViewForOfflineDownloadArea()
            
        case .offlineMask:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(true) )
            animations.append( smallPopViewVisible(false) )
            animations.append( mapViewVisible(true) )
            presentMapMaskViewForOfflineDownloadArea()
            locationSelectionType = .offlineExtent
        }
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            for animation in animations { animation() }
            self?.view.layoutIfNeeded()
        }
    }
}
