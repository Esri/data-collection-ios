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

/**
 `AppContextAwareController` is a `UIViewController` subclass that registers for App Notifications upon with overrideable
 functions so each view controller can adjust accordingly.
 */

enum AppContextChangeNotifications {
    case currentUser, currentMap, hasOfflineMap, locationAuthorization, reachability, workMode, lastSync
}

protocol AppContextNotificationsSubscribable {
    var notifications: [AppContextChangeNotifications] { get }
}

class AppContextAwareController: UIViewController, AppContextNotificationsSubscribable {
    
    var notifications: [AppContextChangeNotifications] { return [] }
    
    private var appContextNotifications: [AppContextChangeNotifications]!
    
    private var observeCurrentUser: NSKeyValueObservation?
    private var observeCurrentMap: NSKeyValueObservation?
    private var observeOfflineMap: NSKeyValueObservation?
    private var observeLocationAuthorization: NSKeyValueObservation?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        appContextNotifications = notifications
        
        if appContextNotifications.contains(.reachability) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveReachabilityNotification(notification:)), name: AppNotifications.reachabilityChanged.name, object: nil)
        }
        
        if appContextNotifications.contains(.workMode) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveWorkModeNotification(notification:)), name: AppNotifications.workModeChanged.name, object: nil)
        }
        
        if appContextNotifications.contains(.lastSync) {
            appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveLastSyncNotification(notification:)), name: AppNotifications.lastSyncChanged.name, object: nil)
        }
        
        if appContextNotifications.contains(.currentUser) {
            observeCurrentUser = appContext.observe(\.user, options: [.new, .old]) { [weak self] (_, _) in
                self?.appCurrentUserDidChange()
            }
        }
        
        if appContextNotifications.contains(.currentMap) {
            observeCurrentMap = appContext.observe(\.currentMap, options:[.new, .old]) { [weak self] (_, _) in
                self?.appCurrentMapDidChange()
            }
        }
        
        if appContextNotifications.contains(.hasOfflineMap) {
            observeOfflineMap = appContext.observe(\.hasOfflineMap, options: [.new, .old]) { [weak self] (_, _) in
                self?.appHasOfflineMapDidChange()
            }
        }
        
        if appContextNotifications.contains(.locationAuthorization) {
            observeLocationAuthorization = appLocation.observe(\.locationAuthorized, options:[.new, .old]) { [weak self] (_, _) in
                // print("[Location Authorization] is authorized: \(appLocation.locationAuthorized)")
                self?.appLocationAuthorizationStatusDidChange()
            }
        }
    }
    
    deinit {
        
        if appContextNotifications.contains(.reachability) {
            appNotificationCenter.removeObserver(self, name: AppNotifications.reachabilityChanged.name, object: nil)
        }
        
        if appContextNotifications.contains(.workMode) {
            appNotificationCenter.removeObserver(self, name: AppNotifications.workModeChanged.name, object: nil)
        }
        
        if appContextNotifications.contains(.lastSync) {
            appNotificationCenter.removeObserver(self, name: AppNotifications.lastSyncChanged.name, object: nil)
        }
        
        if appContextNotifications.contains(.currentUser) {
            observeCurrentUser?.invalidate()
            observeCurrentUser = nil
        }
        
        if appContextNotifications.contains(.currentMap) {
            observeCurrentMap?.invalidate()
            observeCurrentMap = nil
        }
        
        if appContextNotifications.contains(.hasOfflineMap) {
            observeOfflineMap?.invalidate()
            observeOfflineMap = nil
        }
        
        if appContextNotifications.contains(.locationAuthorization) {
            observeLocationAuthorization?.invalidate()
            observeLocationAuthorization = nil
        }
    }
    
    @objc private func recieveReachabilityNotification(notification: Notification) {
        appReachabilityDidChange()
    }
    
    @objc private func recieveWorkModeNotification(notification: Notification) {
        appWorkModeDidChange()
    }
    
    @objc private func recieveLastSyncNotification(notification: Notification) {
        appLastSyncDidChange()
    }
    
    // MARK: Overridable functions
    
    func appReachabilityDidChange() { }
    
    func appWorkModeDidChange() {
        navigationController?.navigationBar.barTintColor = (appContext.workMode == .online) ? appColors.primary : appColors.offline
    }
    
    func appLastSyncDidChange() { }
    
    func appCurrentUserDidChange() { }
    
    func appCurrentMapDidChange() { }
    
    func appHasOfflineMapDidChange() { }
    
    func appLocationAuthorizationStatusDidChange() { }
}
