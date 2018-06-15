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

import Foundation
import ArcGIS

enum LocationSelectionViewType {
    
    case newFeature
    case offlineExtent
    
    var headerText: String {
        switch self {
        case .newFeature:
            return "Choose the location"
        case .offlineExtent:
            return "Select the region of the map to take offline"
        }
    }
    
    var subheaderText: String {
        switch self {
        case .newFeature:
            return "Pan and zoom map under pin"
        case .offlineExtent:
            return "Pan and zoom map within the rectangle"
        }
    }
}

extension MapViewController {
    
    @IBAction func userDidSelectLocation(_ sender: Any) {

        switch locationSelectionType {
            
        case .newFeature:
            prepareNewFeatureForEdit()
            break
            
        case .offlineExtent:
            prepareForOfflineMapDownloadJob()
            break
        }
        
        mapViewMode = .defaultView
    }
    
    @IBAction func userDidCancelSelectLocation(_ sender: Any) {
        
        switch locationSelectionType {
        case .newFeature:
            _ = EphemeralCache.get(objectForKey: EphemeralCacheKeys.newNonSpatialFeature)
            break
        case .offlineExtent:
            hideMapMaskViewForOfflineDownloadArea()
            break
        }
        
        mapViewMode = .defaultView
    }
    
    func adjustForLocationSelectionType() {
        
        selectViewHeaderLabel.text = locationSelectionType.headerText
        selectViewSubheaderLabel.text = locationSelectionType.subheaderText
    }
    
    // MARK : New Feature
    
    func userRequestsAddNewFeature() {
        
        guard mapViewMode != .disabled else {
            return
        }
        
        guard appContext.isLoggedIn else {
            present(loginAlertMessage: "You must log in to add a Feature.")
            return
        }
        
        guard let map = mapView.map, let operationalLayers = map.operationalLayers as? [AGSFeatureLayer], let layers = operationalLayers.featureAddableLayers else {
            present(simpleAlertMessage: "No eligible feature layer that you can add to.")
            return
        }
        
        guard layers.count > 1 else {
            addNewFeatureFor(featureLayer: layers.first!)
            return
        }
        
        let action = UIAlertController(title: nil, message: "Add to feature layer:", preferredStyle: .actionSheet)
        
        for layer in layers {
            
            guard let featureTable = layer.featureTable as? AGSArcGISFeatureTable else {
                continue
            }
            
            let addFeature = UIAlertAction(title: featureTable.tableName, style: .`default`, handler: { [weak self] (action) in
                self?.addNewFeatureFor(featureLayer: layer)
            })
            
            action.addAction(addFeature)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        action.addAction(cancel)
        
        present(action, animated: true, completion: nil)
    }
    
    private func addNewFeatureFor(featureLayer: AGSFeatureLayer) {
        
        currentPopup?.clearSelection()
        currentPopup = nil
        
        guard
            let featureTable = featureLayer.featureTable as? AGSArcGISFeatureTable,
            let newPopup = featureTable.createPopup()
            else {
                present(simpleAlertMessage: "Uh Oh! You are unable to add a new feature.")
                return
        }
        
        EphemeralCache.set(object: newPopup, forKey: EphemeralCacheKeys.newNonSpatialFeature)
        
        mapViewMode = .selectingFeature
    }
    
    private func prepareNewFeatureForEdit() {
        
        guard let newPopup = EphemeralCache.get(objectForKey: EphemeralCacheKeys.newNonSpatialFeature) as? AGSPopup else {
            present(simpleAlertMessage: "Uh Oh! You are unable to add a new record.")
            return
        }
        
        SVProgressHUD.show(withStatus: "Preparing new \(newPopup.tableName ?? "record").")
        
        guard
            let initialViewpoint = mapView.map?.initialViewpoint,
            let spatialRef = initialViewpoint.targetGeometry.spatialReference,
            let centerPoint = AGSGeometryEngine.projectGeometry(mapView.centerAGSPoint(), to: spatialRef) as? AGSPoint,
            AGSGeometryEngine.geometry(centerPoint, within: initialViewpoint.targetGeometry)
            else {
                SVProgressHUD.dismiss()
                present(simpleAlertMessage: "Can't add new \(newPopup.tableName ?? "record") here.")
                return
        }
        
        // Custom Behavior
        
        let proceedAfterCustomBehavior: () -> Void = { [weak self] in
            
            newPopup.geoElement.geometry = centerPoint
            EphemeralCache.set(object: newPopup, forKey: EphemeralCacheKeys.newSpatialFeature)
            
            SVProgressHUD.dismiss()
            
            self?.performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
        }
        
        if shouldEnactCustomBehavior {
            
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter(n: 3)
            
            dispatchGroup.notify(queue: OperationQueue.current?.underlyingQueue ?? .main) {
                proceedAfterCustomBehavior()
            }
            
            enrich(popup: newPopup, withReverseGeocodedDataForPoint: centerPoint) {
                dispatchGroup.leave()
            }
            
            enrich(popup: newPopup, withNeighborhoodIdentifyForPoint: centerPoint) {
                dispatchGroup.leave()
            }
            
            configureDefaultCondition(forPopup: newPopup) {
                dispatchGroup.leave()
            }
        }
        else {
            proceedAfterCustomBehavior()
        }
    }
    
    // MARK : Offline Mask
    
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
