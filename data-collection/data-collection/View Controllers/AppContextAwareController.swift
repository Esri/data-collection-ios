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

class AppContextAwareController: UIViewController {
    
    struct AppContextChangeKey: RawRepresentable, Hashable {
        
        typealias RawValue = String
        
        var rawValue: RawValue
        
        init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        // Needed to satisfy the protocol requirement.
        init?(rawValue: RawValue) {
            self.init(rawValue)
        }
        
        static let currentUser = AppContextChangeKey("AppContextChangeKey.currentUser")
        static let currentMap = AppContextChangeKey("AppContextChange.currentMap")
        static let hasOfflineMap = AppContextChangeKey("AppContextChange.hasOfflineMap")
        static let locationAuthorization = AppContextChangeKey("AppContextChange.locationAuthorization")
        static let reachability = AppContextChangeKey("AppContextChange.reachability")
        static let workMode = AppContextChangeKey("AppContextChange.workMode")
        static let lastSync = AppContextChangeKey("AppContextChange.lastSync")
    }
    
    enum AppContextChangeNotification {
        
        case currentUser((AGSPortalUser?) -> Void)
        case currentMap((AGSMap?) -> Void)
        case hasOfflineMap((Bool) -> Void)
        case locationAuthorization((Bool) -> Void)
        case reachability((Bool) -> Void)
        case workMode((WorkMode) -> Void)
        case lastSync((Date?) -> Void)
        
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
        
        var key: AppContextChangeKey {
            switch self {
            case .currentUser(_):
                return AppContextChangeKey.currentUser
            case .currentMap(_):
                return AppContextChangeKey.currentMap
            case .hasOfflineMap(_):
                return AppContextChangeKey.hasOfflineMap
            case .locationAuthorization(_):
                return AppContextChangeKey.locationAuthorization
            case .reachability(_):
                return AppContextChangeKey.reachability
            case .workMode(_):
                return AppContextChangeKey.workMode
            case .lastSync(_):
                return AppContextChangeKey.lastSync
            }
        }
    }
    
    var appContextNotificationRegistrations: [AppContextChangeNotification] { return [] }
    
    private var appNotifications = [AppContextChangeKey: AppContextChangeNotification]()
    private var appObservations = [NSKeyValueObservation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for notification in appContextNotificationRegistrations {
            appNotifications[notification.key] = notification
        }
        
        if appNotifications.keys.contains(AppContextChangeKey.reachability) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveReachabilityNotification(notification:)), name: .reachabilityDidChange, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKey.workMode) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveWorkModeNotification(notification:)), name: .workModeDidChange, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKey.lastSync) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveLastSyncNotification(notification:)), name: .lastSyncDidChange, object: nil)
        }
        
        if appNotifications.keys.contains(AppContextChangeKey.currentUser) {
            let observeCurrentUser = appContext.observe(\.user, options: [.new, .old]) { [weak self] (_, _) in
                if let change = self?.appNotifications[AppContextChangeKey.currentUser],
                    let completionClosure = change.notificationClosure as? (AGSPortalUser?) -> Void  {
                    DispatchQueue.main.async {
                        completionClosure(appContext.user)
                    }
                }
            }
            appObservations.append(observeCurrentUser)
        }
        
        if appNotifications.keys.contains(AppContextChangeKey.currentMap) {
            let observeCurrentMap = appContext.observe(\.currentMap, options:[.new, .old]) { [weak self] (_, _) in
                if let change = self?.appNotifications[AppContextChangeKey.currentMap],
                    let completionClosure = change.notificationClosure as? (AGSMap?) -> Void  {
                    DispatchQueue.main.async {
                        completionClosure(appContext.currentMap)
                    }
                }
            }
            appObservations.append(observeCurrentMap)
        }
        
        if appNotifications.keys.contains(AppContextChangeKey.hasOfflineMap) {
            let observeOfflineMap = appContext.observe(\.hasOfflineMap, options: [.new, .old]) { [weak self] (_, _) in
                if let change = self?.appNotifications[AppContextChangeKey.hasOfflineMap],
                    let completionClosure = change.notificationClosure as? (Bool) -> Void  {
                    DispatchQueue.main.async {
                        completionClosure(appContext.hasOfflineMap)
                    }
                }
            }
            appObservations.append(observeOfflineMap)
        }
        
        if appNotifications.keys.contains(AppContextChangeKey.locationAuthorization) {
            let observeLocationAuthorization = appLocation.observe(\.locationAuthorized, options:[.new, .old]) { [weak self] (_, _) in
                if let change = self?.appNotifications[AppContextChangeKey.locationAuthorization],
                    let completionClosure = change.notificationClosure as? (Bool) -> Void  {
                    DispatchQueue.main.async {
                        completionClosure(appLocation.locationAuthorized)
                    }
                }
            }
            appObservations.append(observeLocationAuthorization)
        }
    }
    
    deinit {
        appNotifications.removeAll()
        appObservations.removeAll()
    }
    
    @objc private func recieveReachabilityNotification(notification: Notification) {
        
        if let change = appNotifications[AppContextChangeKey.reachability],
            let completionClosure = change.notificationClosure as? (Bool) -> Void  {
            DispatchQueue.main.async {
                completionClosure(appReachability.isReachable)
            }
        }
    }
    
    @objc private func recieveWorkModeNotification(notification: Notification) {
        
        navigationController?.navigationBar.barTintColor = (appContext.workMode == .online) ? appColors.primary : appColors.offline
        
        if let change = appNotifications[AppContextChangeKey.workMode],
            let completionClosure = change.notificationClosure as? (WorkMode) -> Void  {
            DispatchQueue.main.async {
                completionClosure(appContext.workMode)
            }
        }
    }
    
    @objc private func recieveLastSyncNotification(notification: Notification) {
        
        if let change = appNotifications[AppContextChangeKey.lastSync],
            let completionClosure = change.notificationClosure as? (Date?) -> Void  {
            DispatchQueue.main.async {
                completionClosure(appContext.lastSync.date)
            }
        }
    }
}
