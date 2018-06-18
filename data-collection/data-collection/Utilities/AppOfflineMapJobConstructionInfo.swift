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

enum AppOfflineMapJobConstructionInfo {
    
    struct EphemeralCacheKeys {
        static let offlineMapJob = "EphemeralCache.AppOfflineMapJob.Key"
    }
    
    case downloadMapOffline(AGSMap, URL, AGSEnvelope, Double)
    case syncOfflineMap(AGSMap)
    
    var message: String {
        switch self {
        case .downloadMapOffline(_,_,_,_):
            return "Downloading Map Offline"
        case .syncOfflineMap(_):
            return "Synchronizing Offline Map"
        }
    }
    
    var successMessage: String {
        return "Success!"
    }
    
    var errorMessage: String {
        switch self {
        case .downloadMapOffline(_,_,_,_):
            return "Couldn't Download Map"
        case .syncOfflineMap(_):
            return "Couldn't Synchronize Map"
        }
    }
    
    var cancelMessage: String {
        return "Cancelled"
    }
    
    func generateJob() -> AGSJob {
        
        switch self {
            
        case .downloadMapOffline(let map, let directory, let extent, let scale):
            let offlineMapTask = AGSOfflineMapTask(onlineMap: map)
            let offlineMapParameters = AGSGenerateOfflineMapParameters(areaOfInterest: extent, minScale: scale, maxScale: map.maxScale)
            let offlineMapJob = offlineMapTask.generateOfflineMapJob(with: offlineMapParameters, downloadDirectory: directory)
            
            return offlineMapJob
            
        case .syncOfflineMap(let map):
            let offlineMapSyncTask = AGSOfflineMapSyncTask(map: map)
            let offlineMapSyncParameters = AGSOfflineMapSyncParameters()
            offlineMapSyncParameters.syncDirection = .bidirectional
            let offlineMapSyncJob = offlineMapSyncTask.offlineMapSyncJob(with: offlineMapSyncParameters)
            
            return offlineMapSyncJob
        }
    }
}
