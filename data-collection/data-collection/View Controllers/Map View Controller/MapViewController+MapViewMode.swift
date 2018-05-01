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
    // TODO consider backticks
    case `default`
    case disabled
    case selectedFeature
    case selectingFeature
    case offlineMask
}

extension MapViewController {
    
    func adjustForMapViewMode(from: MapViewMode?, to: MapViewMode) {
        
        if let from = from {
            guard from != to else {
                return
            }
        }
        
        let smallPopViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                self?.popupsContainerView.alpha = visible.asAlpha
                self?.smallPopupViewController?.view.alpha = visible.asAlpha
                self?.featureDetailViewBottomConstraint.constant = visible ? 8 : 28
            }
        }
        
        let selectViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                self?.selectView.alpha = visible.asAlpha
                guard let selectView = self?.selectView else {
                    return
                }
                self?.selectViewTopConstraint.constant = visible ? 0 : selectView.frame.height
            }
        }
        
        let mapViewVisible: (Bool) -> UIViewAnimations = { [weak self] (visible) in
            return {
                self?.mapView.alpha = visible ? 1.0 : 0.5
            }
        }
        
        var animations = [UIViewAnimations]()
        
        if let from = from {
            switch from {
            case .offlineMask:
                hideMapMaskViewForOfflineDownloadArea()
            case .disabled:
                animations.append( mapViewVisible(true) )
                view.isUserInteractionEnabled = true
                break
            default:
                break
            }
        }
        
        switch to {
            
        case .`default`:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(false) )

        case .disabled:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(false) )
            animations.append( mapViewVisible(false) )
            view.isUserInteractionEnabled = false
            
        case .selectingFeature:
            pinDropView.pinDropped = true
            animations.append( selectViewVisible(true) )
            animations.append( smallPopViewVisible(false) )
            locationSelectionType = .newFeature
            
        case .selectedFeature:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(true) )
            
        case .offlineMask:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(true) )
            animations.append( smallPopViewVisible(false) )
            locationSelectionType = .offlineExtent
            presentMapMaskViewForOfflineDownloadArea()
        }
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            for animation in animations { animation() }
            self?.view.layoutIfNeeded()
        }
    }
}
