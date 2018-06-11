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


extension AppContainerViewController: DrawerViewControllerDelegate {
    
    func drawerViewController(didRequestWorkOnline drawerViewController: DrawerViewController) {
        appContext.setWorkModeOnlineWithMapFromPortal()
    }
    
    func drawerViewController(didRequestWorkOffline drawerViewController: DrawerViewController) {
        if !appContext.setMapFromOfflineMobileMapPackage() {
            drawerShowing = false
            mapViewController?.prepareMapMaskViewForOfflineDownloadArea()
        }
    }
    
    func drawerViewController(didRequestLoginLogout drawerViewController: DrawerViewController) {
        if appContext.isLoggedIn {
            var message: String = ""
            if appContext.hasOfflineMap {
                message = "Logging out will delete your offline map. Are you sure you want to proceed?"
            }
            let alert = UIAlertController.multiAlert(title: "Log out?", message: message, actionTitle: "Log out", action: { (_) in
                appContext.logout()
                if appContext.hasOfflineMap {
                    do {
                        try appContext.deleteOfflineMapAndAttemptToGoOnline()
                    }
                    catch {
                        print("[Error] couldn't delete offline map", error.localizedDescription)
                    }
                }
            })
            self.present(alert, animated: true, completion: nil)
        }
        else {
            appContext.login()
        }
    }
    
    func drawerViewController(didRequestSyncJob drawerViewController: DrawerViewController) {
        
        guard let map = appContext.offlineMap else {
            print("[Error: Offline Map Sync Job] no offline map to sync")
            return
        }
        
        let offlineJob = AppOfflineMapJobConstructionInfo.syncOfflineMap(map)
        EphemeralCache.set(object: offlineJob, forKey: AppOfflineMapJobConstructionInfo.ephemeralCacheKey)
        performSegue(withIdentifier: "presentJobStatusViewController", sender: nil)
    }
    
    func drawerViewController(didRequestDeleteMap drawerViewController: DrawerViewController) {
        
        let alert = UIAlertController.multiAlert(title: nil,
                                                 message: "Are you sure you want to delete your offline map?",
                                                 actionTitle: "Delete",
                                                 action: { (action) in
                                                    do {
                                                        try appContext.deleteOfflineMapAndAttemptToGoOnline()
                                                    }
                                                    catch {
                                                        print("[Error] couldn't delete offline map", error.localizedDescription)
                                                    }
        },
                                                 cancelTitle: "Cancel",
                                                 cancel: nil)
        
        present(alert, animated: true, completion: nil)
    }
}
