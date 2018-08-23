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

/**
 `UIViewController` is a `UIViewController` subclass that registers for App Notifications upon with overrideable
 functions so each view controller can adjust accordingly.
 */


class AppContextChangeHandler {
    
    private var appChanges = [AppContextChange.Key: AppContextChange]()
    private var appObservations = [NSKeyValueObservation]()
    
    func subscribe(toChanges changes: [AppContextChange]) {
        
        changes.forEach { (change) in subscribe(toChange: change) }
    }
    
    func subscribe(toChange change: AppContextChange) {
        
        switch change {
        case .currentUser(let closure):
            let observeCurrentUser = appContext.observe(\.user, options: [.new, .old]) { (_, _) in
                DispatchQueue.main.async { closure(appContext.user) }
            }
            appObservations.append(observeCurrentUser)
            
        case .currentMap(let closure):
            let observeCurrentMap = appContext.observe(\.currentMap, options:[.new, .old]) { (_, _) in
                DispatchQueue.main.async { closure(appContext.currentMap) }
            }
            appObservations.append(observeCurrentMap)
            
        case .hasOfflineMap(let closure):
            let observeOfflineMap = appContext.observe(\.hasOfflineMap, options: [.new, .old]) { (_, _) in
                DispatchQueue.main.async { closure(appContext.hasOfflineMap) }
            }
            appObservations.append(observeOfflineMap)
            
        case .locationAuthorization(let closure):
            let observeLocationAuthorization = appLocation.observe(\.locationAuthorized, options:[.new, .old]) { (_, _) in
                DispatchQueue.main.async { closure(appLocation.locationAuthorized) }
            }
            appObservations.append(observeLocationAuthorization)
            
        case .reachability(_):
            appChanges[change.key] = change
            appNotificationCenter.addObserver(self, selector: #selector(AppContextChangeHandler.recieveReachabilityNotification(notification:)), name: .reachabilityDidChange, object: nil)
        
        case .workMode(_):
            appChanges[change.key] = change
            appNotificationCenter.addObserver(self, selector: #selector(AppContextChangeHandler.recieveWorkModeNotification(notification:)), name: .workModeDidChange, object: nil)
        
        case .lastSync(_):
            appChanges[change.key] = change
            appNotificationCenter.addObserver(self, selector: #selector(AppContextChangeHandler.recieveLastSyncNotification(notification:)), name: .lastSyncDidChange, object: nil)
        }
    }
    
    @objc private func recieveReachabilityNotification(notification: Notification) {
        
        if let change = appChanges[AppContextChange.Key.reachability],
            let completionClosure = change.notificationClosure as? (Bool) -> Void  {
            DispatchQueue.main.async {
                completionClosure(appReachability.isReachable)
            }
        }
    }
    
    @objc private func recieveWorkModeNotification(notification: Notification) {
        
        if let change = appChanges[AppContextChange.Key.workMode],
            let completionClosure = change.notificationClosure as? (WorkMode) -> Void  {
            DispatchQueue.main.async {
                completionClosure(appContext.workMode)
            }
        }
    }
    
    @objc private func recieveLastSyncNotification(notification: Notification) {
        
        if let change = appChanges[AppContextChange.Key.lastSync],
            let completionClosure = change.notificationClosure as? (Date?) -> Void  {
            DispatchQueue.main.async {
                completionClosure(appContext.lastSync.date)
            }
        }
    }
    
    deinit {
        appChanges.removeAll()
        appObservations.removeAll()
    }
}
