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
 `AppContextAwareController` is a `UIViewController` subclass that registers for App Notifications upon with overrideable
 functions so each view controller can adjust accordingly.
 */

struct AppContextChangeKeys {
    
    static let currentUser = "appContextChange.currentUser"
    static let currentMap = "appContextChange.currentMap"
    static let hasOfflineMap = "appContextChange.hasOfflineMap"
    static let locationAuthorization = "appContextChange.locationAuthorization"
    static let reachability = "appContextChange.reachability"
    static let workMode = "appContextChange.workMode"
    static let lastSync = "appContextChange.lastSync"
}

enum AppContextChangeNotification {
    
    case currentUser((AGSPortalUser?) -> Void)
    case currentMap((AGSMap?) -> Void)
    case hasOfflineMap((Bool) -> Void)
    case locationAuthorization((Bool) -> Void)
    case reachability((Bool) -> Void)
    case workMode((WorkMode) -> Void)
    case lastSync((Date?) -> Void)
    
    var key: String {
        switch self {
        case .currentUser(_):
            return AppContextChangeKeys.currentUser
        case .currentMap(_):
            return AppContextChangeKeys.currentMap
        case .hasOfflineMap(_):
            return AppContextChangeKeys.hasOfflineMap
        case .locationAuthorization(_):
            return AppContextChangeKeys.locationAuthorization
        case .reachability(_):
            return AppContextChangeKeys.reachability
        case .workMode(_):
            return AppContextChangeKeys.workMode
        case .lastSync(_):
            return AppContextChangeKeys.lastSync
        }
    }
    
    var notificationClosure: Any {
        switch self {
        case .currentUser(let closure):
            return closure
        case .currentMap(let closure):
            return closure
        case .hasOfflineMap(let closure):
            return closure
        case .locationAuthorization(let closure):
            return closure
        case .reachability(let closure):
            return closure
        case .workMode(let closure):
            return closure
        case .lastSync(let closure):
            return closure
        }
    }
}


class AppContextAwareController: UIViewController {
    
    var appContextNotificationRegistrations: [AppContextChangeNotification] { return [] }
        
    private var appNotifications = [String: AppContextChangeNotification]()
    
    private var observeCurrentUser: NSKeyValueObservation?
    private var observeCurrentMap: NSKeyValueObservation?
    private var observeOfflineMap: NSKeyValueObservation?
    private var observeLocationAuthorization: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for notification in appContextNotificationRegistrations {
            appNotifications[notification.key] = notification
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.reachability) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveReachabilityNotification(notification:)), name: AppNotifications.reachabilityChanged.name, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.workMode) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveWorkModeNotification(notification:)), name: AppNotifications.workModeChanged.name, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.lastSync) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveLastSyncNotification(notification:)), name: AppNotifications.lastSyncChanged.name, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.currentUser) {
            observeCurrentUser = appContext.observe(\.user, options: [.new, .old]) { [weak self] (_, _) in
                if let change = self?.appNotifications[AppContextChangeKeys.currentUser],
                    let completionClosure = change.notificationClosure as? (AGSPortalUser?) -> Void  {
                        completionClosure(appContext.user)
                }
            }
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.currentMap) {
            observeCurrentMap = appContext.observe(\.currentMap, options:[.new, .old]) { [weak self] (_, _) in
                if let change = self?.appNotifications[AppContextChangeKeys.currentMap],
                    let completionClosure = change.notificationClosure as? (AGSMap?) -> Void  {
                    completionClosure(appContext.currentMap)
                }
            }
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.hasOfflineMap) {
            observeOfflineMap = appContext.observe(\.hasOfflineMap, options: [.new, .old]) { [weak self] (_, _) in
                if let change = self?.appNotifications[AppContextChangeKeys.hasOfflineMap],
                    let completionClosure = change.notificationClosure as? (Bool) -> Void  {
                    completionClosure(appContext.hasOfflineMap)
                }
            }
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.locationAuthorization) {
            observeLocationAuthorization = appLocation.observe(\.locationAuthorized, options:[.new, .old]) { [weak self] (_, _) in
                // print("[Location Authorization] is authorized: \(appLocation.locationAuthorized)")
                if let change = self?.appNotifications[AppContextChangeKeys.locationAuthorization],
                    let completionClosure = change.notificationClosure as? (Bool) -> Void  {
                    completionClosure(appLocation.locationAuthorized)
                }
            }
        }
    }
    
    deinit {
        
        if appNotifications.keys.contains(AppContextChangeKeys.reachability) {
            appNotificationCenter.removeObserver(self, name: AppNotifications.reachabilityChanged.name, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.workMode) {
            appNotificationCenter.removeObserver(self, name: AppNotifications.workModeChanged.name, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.lastSync) {
            appNotificationCenter.removeObserver(self, name: AppNotifications.lastSyncChanged.name, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.currentUser) {
            observeCurrentUser?.invalidate()
            observeCurrentUser = nil
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.currentMap) {
            observeCurrentMap?.invalidate()
            observeCurrentMap = nil
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.hasOfflineMap) {
            observeOfflineMap?.invalidate()
            observeOfflineMap = nil
        }
        
        if appNotifications.keys.contains(AppContextChangeKeys.locationAuthorization) {
            observeLocationAuthorization?.invalidate()
            observeLocationAuthorization = nil
        }
    }
    
    @objc private func recieveReachabilityNotification(notification: Notification) {
        
        if let change = appNotifications[AppContextChangeKeys.reachability],
            let completionClosure = change.notificationClosure as? (Bool) -> Void  {
            completionClosure(appReachability.isReachable)
        }
    }
    
    @objc private func recieveWorkModeNotification(notification: Notification) {
        
        navigationController?.navigationBar.barTintColor = (appContext.workMode == .online) ? appColors.primary : appColors.offline
        
        if let change = appNotifications[AppContextChangeKeys.workMode],
            let completionClosure = change.notificationClosure as? (WorkMode) -> Void  {
            completionClosure(appContext.workMode)
        }
    }
    
    @objc private func recieveLastSyncNotification(notification: Notification) {
        
        if let change = appNotifications[AppContextChangeKeys.lastSync],
            let completionClosure = change.notificationClosure as? (Date?) -> Void  {
            completionClosure(appContext.lastSync.date)
        }
    }
}
