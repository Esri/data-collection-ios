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

protocol AppContextAware {
    var changeHandler: AppContextAwareChangeHandler { get }
}

enum AppContextChange {
    
    struct Key: RawRepresentable, Hashable {
        
        typealias RawValue = String
        
        var rawValue: RawValue
        
        init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        // Needed to satisfy the protocol requirement.
        init?(rawValue: RawValue) {
            self.init(rawValue)
        }
        
        static let currentUser = Key("AppContextChangeKey.currentUser")
        static let currentMap = Key("AppContextChange.currentMap")
        static let hasOfflineMap = Key("AppContextChange.hasOfflineMap")
        static let locationAuthorization = Key("AppContextChange.locationAuthorization")
        static let reachability = Key("AppContextChange.reachability")
        static let workMode = Key("AppContextChange.workMode")
        static let lastSync = Key("AppContextChange.lastSync")
    }
    
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
    
    var key: Key {
        switch self {
        case .currentUser(_):
            return Key.currentUser
        case .currentMap(_):
            return Key.currentMap
        case .hasOfflineMap(_):
            return Key.hasOfflineMap
        case .locationAuthorization(_):
            return Key.locationAuthorization
        case .reachability(_):
            return Key.reachability
        case .workMode(_):
            return Key.workMode
        case .lastSync(_):
            return Key.lastSync
        }
    }
}

class AppContextAwareChangeHandler {
    
    private var appChanges = [AppContextChange.Key: AppContextChange]()
    private var appObservations = [NSKeyValueObservation]()
    
    func subscribe(toChanges changes: [AppContextChange]) {
        
        changes.forEach { (change) in subscribe(toChange: change) }
    }
    
    func subscribe(toChange change: AppContextChange) {
        
        appChanges[change.key] = change
        
        switch change {
        case .currentUser(let closure):
            let observeCurrentUser = appContext.observe(\.user, options: [.new, .old]) { (_, _) in
                DispatchQueue.main.async { closure(appContext.user) }
            }
            appObservations.append(observeCurrentUser)
            
        case .currentMap(_):
            let observeCurrentMap = appContext.observe(\.currentMap, options:[.new, .old]) { [weak self] (_, _) in
                if let change = self?.appChanges[AppContextChange.Key.currentMap], let completionClosure = change.notificationClosure as? (AGSMap?) -> Void  {
                    DispatchQueue.main.async { completionClosure(appContext.currentMap) }
                }
            }
            appObservations.append(observeCurrentMap)
            
        case .hasOfflineMap(_):
            let observeOfflineMap = appContext.observe(\.hasOfflineMap, options: [.new, .old]) { [weak self] (_, _) in
                if let change = self?.appChanges[AppContextChange.Key.hasOfflineMap], let completionClosure = change.notificationClosure as? (Bool) -> Void  {
                    DispatchQueue.main.async { completionClosure(appContext.hasOfflineMap) }
                }
            }
            appObservations.append(observeOfflineMap)
            
        case .locationAuthorization(_):
            let observeLocationAuthorization = appLocation.observe(\.locationAuthorized, options:[.new, .old]) { [weak self] (_, _) in
                if let change = self?.appChanges[AppContextChange.Key.locationAuthorization], let completionClosure = change.notificationClosure as? (Bool) -> Void  {
                    DispatchQueue.main.async { completionClosure(appLocation.locationAuthorized) }
                }
            }
            appObservations.append(observeLocationAuthorization)
            
        case .reachability(_):
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareChangeHandler.recieveReachabilityNotification(notification:)), name: .reachabilityDidChange, object: nil)
        case .workMode(_):
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareChangeHandler.recieveWorkModeNotification(notification:)), name: .workModeDidChange, object: nil)
        case .lastSync(_):
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareChangeHandler.recieveLastSyncNotification(notification:)), name: .lastSyncDidChange, object: nil)
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
}
