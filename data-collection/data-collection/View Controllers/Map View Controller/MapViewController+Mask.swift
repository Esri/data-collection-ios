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
    
    func prepareMapMaskViewForOfflineDownloadArea() {
        
        mapViewMode = .offlineMask
    }
    
    func presentMapMaskViewForOfflineDownloadArea() {
        
        guard let locationSelectionView = view.viewWithTag(1001), let maskView = view.viewWithTag(1002) else {
            return
        }

        maskView.isHidden = false
        view.bringSubview(toFront: maskView)
        view.bringSubview(toFront: locationSelectionView)
    }
    
    func hideMapMaskViewForOfflineDownloadArea() {
        
        guard let maskView = view.viewWithTag(1002) else {
            return
        }
        
        maskView.isHidden = true
        view.sendSubview(toBack: maskView)
    }
    
    func prepareForOfflineMapDownloadJob() {
        
        guard let mask = view.viewWithTag(1003) else {
            return
        }
        
        let nw = mask.frame.origin
        let se = CGPoint(x: mask.frame.maxX, y: mask.frame.maxY)
        
        let agsNW = mapView.screen(toLocation: nw)
        let agsSE = mapView.screen(toLocation: se)
        
        let envelope = AGSEnvelope(min: agsNW, max: agsSE)
        
        delegate?.mapViewController(self, didSelect: envelope)
    }
}
