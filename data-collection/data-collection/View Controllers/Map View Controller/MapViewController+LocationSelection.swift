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
        
        mapViewMode = .selectingFeature
    }
    
    @IBAction func userDidSelectLocation(_ sender: Any) {
        
        guard let initialViewpoint = mapView.map?.initialViewpoint else {
            present(simpleAlertMessage: "No map viewpoint set. Contact map publisher.")
            return
        }
        
        guard let centerPoint = AGSGeometryEngine.projectGeometry(mapView.centerAGSPoint(), to: AGSSpatialReference.wgs84()), AGSGeometryEngine.geometry(centerPoint, within: initialViewpoint.targetGeometry) else {
            present(simpleAlertMessage: "Can't add feature, you are outside the bounds of your map.")
            return
        }
        
        switch locationSelectionType {
        case .newFeature:
            break
        case .offlineExtent:
            prepareForOfflineMapDownloadJob()
            break
        }
        
        mapViewMode = .`default`
    }
    
    @IBAction func userDidCancelSelectLocation(_ sender: Any) {
        
        switch locationSelectionType {
        case .newFeature:
            break
        case .offlineExtent:
            hideMapMaskViewForOfflineDownloadArea()
            break
        }
        
        mapViewMode = .`default`
    }
    
    func adjustForLocationSelectionType() {
        
        selectViewHeaderLabel.text = locationSelectionType.headerText
        selectViewSubheaderLabel.text = locationSelectionType.subheaderText
    }
}
