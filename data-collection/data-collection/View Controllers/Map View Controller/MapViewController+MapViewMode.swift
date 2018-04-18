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
    case `default`
    case disabled
    case selectedFeature
    case selectingFeature
    case offlineMask
    case offlineDownload
    case noMap
}

extension MapViewController {
    
    func adjustForMapViewMode() {
        
        let smallPopViewVisible: (Bool) -> UIViewAnimations = { [unowned mvc = self] (visible) in
            return {
                mvc.popupsContainerView.alpha = visible.asAlpha
                mvc.smallPopupViewController?.view.alpha = visible.asAlpha
                mvc.featureDetailViewBottomConstraint.constant = visible ? 8 : 28
            }
        }
        
        let selectViewVisible: (Bool) -> UIViewAnimations = { [unowned mvc = self] (visible) in
            return {
                mvc.selectViewTopConstraint.constant = visible ? 0 : -mvc.selectView.frame.height
                mvc.selectView.alpha = visible.asAlpha
            }
        }
        
        var animations = [UIViewAnimations]()
        
        switch mapViewMode {
            
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
            
        default:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(false) )
        }
        
        UIView.animate(withDuration: 0.2) { [unowned mvc = self] in
            for animation in animations { animation() }
            mvc.view.layoutIfNeeded()
        }
    }
}
