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

extension MapViewController: AGSGeoViewTouchDelegate {
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        query(geoView, atScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    func geoView(_ geoView: AGSGeoView, didEndLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        query(geoView, atScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    private func query(_ geoView: AGSGeoView, atScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //
        //        guard let map = mapView.map, map.loadStatus == .loaded, newTreeUIVisible == false, let treeManager = appTreesManager else {
        //            return
        //        }
        //
        //        selectedTreeDetailViewLoading = true
        //
        //        queryForTreeAtMapPoint?.cancel()
        //        queryForTreeAtMapPoint = nil
        //
        //        // Extension bridge between AGSGeoView identifyTree(::::::) with ArcGIS runtime feature service layers.
        //        // See: AGSGeoView+Extensions.swift
        //        queryForTreeAtMapPoint = geoView.identifyTree(atScreenPoint: screenPoint, tolerance: 8, returnPopupsOnly: false, maximumResults: 8)  { [weak self] (result) in
        //
        //            treeManager.clearSelections()
        //
        //            guard let queryResult = result else {
        //                self?.selectedTree = nil
        //                self?.queryForTreeAtMapPoint = nil
        //                return
        //            }
        //
        //            guard
        //                let features = queryResult.geoElements as? [AGSArcGISFeature],
        //                let feature = features.featureNearestTo(mapPoint: mapPoint)
        //                else {
        //
        //                    self?.mapViewNotificationBarLabel.showLabel(withNotificationMessage: "Did not find a tree at that location.", forDuration: 2.0)
        //                    self?.selectedTree = nil
        //                    self?.queryForTreeAtMapPoint = nil
        //                    return
        //            }
        //
        //            treeManager.tree(forSelectedFeature: feature) { (tree) in
        //
        //                self?.selectedTree = tree
        //                self?.queryForTreeAtMapPoint = nil
        //
        //                if let point = feature.geometry as? AGSPoint, let scale = self?.mapView.mapScale {
        //
        //                    let viewpoint = AGSViewpoint(center: point, scale: scale)
        //                    self?.mapView.setViewpoint(viewpoint, duration: 1.2, completion: nil)
        //                }
        //            }
        //        }
    }
}
