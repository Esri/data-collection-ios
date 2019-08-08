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

extension MapViewController {
    
    @IBAction func userDidSelectLocation(_ sender: Any) {
        
        if mapViewMode == .selectingFeature {
            prepareNewFeatureForEdit()
        }
        else if mapViewMode == .offlineMask {
            prepareForOfflineMapDownloadJob()
        }
        
        mapViewMode = .defaultView
    }
    
    @IBAction func userDidCancelSelectLocation(_ sender: Any) {
        
        if mapViewMode == .selectingFeature {
            EphemeralCache.remove(objectForKey: EphemeralCacheKeys.newNonSpatialFeature)
        }
        else if mapViewMode == .offlineMask {
            hideMapMaskViewForOfflineDownloadArea()
        }
        
        mapViewMode = .defaultView
    }
    
    // MARK : New Feature
    
    func userRequestsAddNewFeature() {
        
        guard mapViewMode != .disabled else {
            return
        }
        
        guard let map = mapView.map, let layers = (map.operationalLayers as? [AGSFeatureLayer])?.featureAddableLayers, layers.count > 0 else {
            present(simpleAlertMessage: "No eligible feature layer that you can add to.")
            return
        }
                
        if layers.count == 1  {
            // There is only one eligible layer, begin the process of adding a new feature for that layer.
            addNewFeatureFor(featureLayer: layers.first!)
            return
        }
        else {
            // Find the layer to which the new record will be added.
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
            
            action.addAction(.cancel())
            
            present(action, animated: true, completion: nil)
        }
    }
    
    private func addNewFeatureFor(featureLayer: AGSFeatureLayer) {
        
        clearCurrentPopup()
        
        guard
            let featureTable = featureLayer.featureTable as? AGSArcGISFeatureTable,
            let newPopup = featureTable.createPopup()
            else {
                present(simpleAlertMessage: "Unable to add a new feature.")
                mapViewMode = .defaultView
                return
        }
        
        let newRichPopup = RichPopup(popup: newPopup)
        
        if let relationships = newRichPopup.relationships {
            
            SVProgressHUD.show(withStatus: String(format: "Creating %@", (newRichPopup.tableName ?? "Feature")))

            relationships.load(completion: { [weak self] (error) in
                
                SVProgressHUD.dismiss()
                
                guard let self = self else { return }
                
                if let error = error  {
                    self.present(simpleAlertMessage: error.localizedDescription)
                }
                else {
                    EphemeralCache.set(object: newRichPopup, forKey: EphemeralCacheKeys.newNonSpatialFeature)
                    
                    self.mapViewMode = .selectingFeature
                }
            })
        }
        else {
            
            EphemeralCache.set(object: newRichPopup, forKey: EphemeralCacheKeys.newNonSpatialFeature)
            
            self.mapViewMode = .selectingFeature
        }
    }
    
    private func prepareNewFeatureForEdit() {
        
        guard let newPopup = EphemeralCache.get(objectForKey: EphemeralCacheKeys.newNonSpatialFeature) as? RichPopup else {
            present(simpleAlertMessage: "Unable to add a new record.")
            return
        }
        
        SVProgressHUD.setContainerView(self.view)
        SVProgressHUD.show(withStatus: String(format: "Preparing new %@.", (newPopup.tableName ?? "record")))
        
        let centerPoint = mapView.centerAGSPoint
        
        // Custom Behavior
        
        func proceedAfterCustomBehavior() {
            
            newPopup.geoElement.geometry = centerPoint
            EphemeralCache.set(object: newPopup, forKey: EphemeralCacheKeys.newSpatialFeature)
            
            SVProgressHUD.dismiss()
            SVProgressHUD.setContainerView(nil)
            
            self.performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
        }
        
        if shouldEnactCustomBehavior {
            
            configureDefaultCondition(forPopup: newPopup)
            
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter(n: 2)
            
            dispatchGroup.notify(queue: OperationQueue.current?.underlyingQueue ?? .main) {
                proceedAfterCustomBehavior()
            }
            
            enrich(popup: newPopup, withReverseGeocodedDataForPoint: centerPoint) {
                dispatchGroup.leave()
            }
            
            enrich(popup: newPopup, withNeighborhoodIdentifyForPoint: centerPoint) {
                dispatchGroup.leave()
            }
        }
        else {
            proceedAfterCustomBehavior()
        }
    }
    
    // MARK : Offline Mask
    
    func prepareMapMaskViewForOfflineDownloadArea() {
        
        clearCurrentPopup()
        mapViewMode = .offlineMask
    }
    
    func presentMapMaskViewForOfflineDownloadArea() {
        
        maskViewContainer.isHidden = false
        view.bringSubviewToFront(maskViewController.view)
    }
    
    func hideMapMaskViewForOfflineDownloadArea() {

        maskViewContainer.isHidden = true
        view.sendSubviewToBack(maskViewController.view)
    }
    
    private func prepareForOfflineMapDownloadJob() {
        
        do {
            let geometry = try mapView.convertExtent(fromRect: maskViewController.maskRect)
            delegate?.mapViewController(self, didSelect: geometry)
        }
        catch {
            print("[Error: AGSMapView]", error.localizedDescription)
            present(simpleAlertMessage: "Could not determine extent for offline map.")
        }
    }
}
