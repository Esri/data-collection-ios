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
            EphemeralCache.shared.removeObject(forKey: .newNonSpatialFeature)
        }
        else if mapViewMode == .offlineMask {
            hideMapMaskViewForOfflineDownloadArea()
        }
        
        mapViewMode = .defaultView
    }
    
    // MARK : New Feature
    
    struct MapNoElegibleLayersError: LocalizedError {
        var errorDescription: String? { "No feature layers of this map can be added to." }
    }
    
    func userRequestsAddNewFeature(_ barButtonItem: UIBarButtonItem?) {
        
        guard mapViewMode != .disabled else { return }
        
        guard let map = mapView.map, let layers = (map.operationalLayers as? [AGSFeatureLayer])?.featureAddableLayers, layers.count > 0 else {
            showError(MapNoElegibleLayersError())
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
            
            action.popoverPresentationController?.barButtonItem = barButtonItem
            present(action, animated: true, completion: nil)
        }
    }
    
    struct CannotCreateNewFeatureError: LocalizedError {
        let layer: AGSFeatureLayer
        var errorDescription: String? {
            String(format: "Cannot create new feature for layer, %@", layer.name)
        }
    }
    
    private func addNewFeatureFor(featureLayer: AGSFeatureLayer) {
        
        clearCurrentPopup()
        
        guard
            let featureTable = featureLayer.featureTable as? AGSArcGISFeatureTable,
            let newPopup = featureTable.createPopup()
            else {
                showError(CannotCreateNewFeatureError(layer: featureLayer))
                mapViewMode = .defaultView
                return
        }
        
        let newRichPopup = RichPopup(popup: newPopup)
        
        if let relationships = newRichPopup.relationships {
            UIApplication.shared.showProgressHUD(
                String(format: "Creating %@", (newRichPopup.tableName ?? "Feature"))
            )
            relationships.load(completion: { [weak self] (error) in
                UIApplication.shared.hideProgressHUD()
                guard let self = self else { return }

                if let error = error  {
                    self.showError(error)
                }
                else {
                    EphemeralCache.shared.setObject(
                        newRichPopup,
                        forKey: .newNonSpatialFeature
                    )
                    
                    self.mapViewMode = .selectingFeature
                }
            })
        }
        else {
            
            EphemeralCache.shared.setObject(
                newRichPopup,
                forKey: .newNonSpatialFeature
            )
            
            self.mapViewMode = .selectingFeature
        }
    }
    
    struct UnknownError: LocalizedError {
        var errorDescription: String? { "An unknown error occured." }
    }
    
    private func prepareNewFeatureForEdit() {
        
        guard let newPopup = EphemeralCache.shared.object(forKey: .newNonSpatialFeature) as? RichPopup else {
            showError(UnknownError())
            return
        }
        
        UIApplication.shared.showProgressHUD(
            String(format: "Preparing new %@.", (newPopup.tableName ?? "record"))
        )
        
        let centerPoint = mapView.centerAGSPoint
        
        // Custom Behavior
        
        func proceedAfterCustomBehavior() {
            
            newPopup.geoElement.geometry = centerPoint
            EphemeralCache.shared.setObject(
                newPopup,
                forKey: .newSpatialFeature
            )
            
            UIApplication.shared.hideProgressHUD()
            
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
        
        guard let map = mapView.map else { return }
                
        do {
            let geometry = try mapView.convertExtent(
                fromRect: maskViewController.maskRect
            )
            let job = try appContext.offlineMapManager.stageOnDemandDownloadMapJob(
                map,
                extent: geometry,
                scale: map.minScale
            )
            EphemeralCache.shared.setObject(job, forKey: "OfflineMapJobID")
            performSegue(withIdentifier: "presentJobStatusViewController", sender: nil)
        }
        catch {
            showError(error)
        }
    }
}

// MARK: Map View Center Point

private extension AGSMapView {
    
    /// An `AGSPoint` representing the center point of the `AGSMapView`'s frame, in the `AGSMapView`'s spatial reference.
    var centerAGSPoint: AGSPoint {
        return screen(toLocation: bounds.center)
    }
}

// MARK: Extent from CGRect

private extension AGSMapView {
    
    /// Convert a `CGRect` to an `AGSPolygon` in relation to the `AGSMapView`'s bounds.
    ///
    /// - Parameter rect: The rect in point space that is to be converted to a spatial rectangular polygon.
    ///
    /// - Returns: The newly created geometry.
    ///
    /// - Throws: An error if the `fromRect` parameter cannot be contained by the map view's bounds.
    
    func convertExtent(fromRect rect: CGRect) throws -> AGSGeometry {
        
        guard bounds.contains(rect) else {
            fatalError("The CGRect \(rect) provided is outside of the map view's bounds \(bounds).")
        }
        
        let nw = rect.origin
        let ne = CGPoint(x: rect.maxX, y: rect.minY)
        let se = CGPoint(x: rect.maxX, y: rect.maxY)
        let sw = CGPoint(x: rect.minX, y: rect.maxY)

        let agsNW = screen(toLocation: nw)
        let agsNE = screen(toLocation: ne)
        let agsSE = screen(toLocation: se)
        let agsSW = screen(toLocation: sw)

        return AGSPolygon(points: [agsNW, agsNE, agsSE, agsSW])
    }
}
