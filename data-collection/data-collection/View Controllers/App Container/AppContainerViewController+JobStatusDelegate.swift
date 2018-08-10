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

extension AppContainerViewController: JobStatusViewControllerDelegate {
    
    func jobStatusViewController(didEndAbruptly jobStatusViewController: JobStatusViewController) {
        print("[Error: Offline Map Job] unknown error!")
        jobStatusViewController.dismissAfter(1.2, animated: true, completion: nil)
    }
    
    func jobStatusViewController(_ jobStatusViewController: JobStatusViewController, didEndWithError error: Error) {
        print("[Error: Offline Map Job]", error.localizedDescription)
        jobStatusViewController.dismissAfter(1.2, animated: true, completion: nil)
    }
    
    func jobStatusViewController(_ jobStatusViewController: JobStatusViewController, didEndWithResult result: Any) {
        if let _ = result as? AGSOfflineMapSyncResult {
            appContext.lastSync.setNow()
            print("[Offline Map Sync Result] success")
        }
        else if let _ = result as? AGSGenerateOfflineMapResult {
            print("[Generate Offline Map Result] success")
            do {
                try appContext.moveDownloadedMapToOfflineMapDirectory()
                appContext.lastSync.setNow()
                appContext.loadOfflineMobileMapPackageAndSetMap()
            }
            catch {
                print("[Error] Moving Downloaded Map", error.localizedDescription)
                try? appContext.deleteOfflineMapAndAttemptToGoOnline()
                return
            }
        }
        jobStatusViewController.dismissAfter(1.2, animated: true, completion: nil)
    }
}
