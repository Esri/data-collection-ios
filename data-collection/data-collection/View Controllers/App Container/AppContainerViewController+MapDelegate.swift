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

extension AppContainerViewController: MapViewControllerDelegate {
    
    func mapViewController(_ mapViewController: MapViewController, didSelect extent: AGSGeometry) {
        
        do {
            try FileManager.default.prepareTemporaryOfflineMapDirectory()
        }
        catch {
            print("[Error]", error.localizedDescription)
            present(simpleAlertMessage: "Something went wrong taking the map offline.")
            return
        }
        
        guard let map = mapViewController.mapView.map else {
            present(simpleAlertMessage: "Something went wrong taking the map offline.")
            return
        }
        
        let scale = mapViewController.mapView.mapScale
        let directory: URL = .temporaryOfflineMapDirectoryURL(forWebMapItemID: AppConfiguration.webMapItemID)
        let offlineJob = AppOfflineMapJobConstructionInfo.downloadMapOffline(map, directory, extent, scale)
        
        EphemeralCache.set(object: offlineJob, forKey: AppOfflineMapJobConstructionInfo.EphemeralCacheKeys.offlineMapJob)
        
        performSegue(withIdentifier: "presentJobStatusViewController", sender: nil)
    }
    
    func mapViewController(_ mapViewController: MapViewController, shouldAllowNewFeature: Bool) {
        showAddFeatureBarButton = shouldAllowNewFeature
    }
    
    func mapViewController(_ mapViewController: MapViewController, didUpdateTitle title: String) {
        self.title = title
    }
}
