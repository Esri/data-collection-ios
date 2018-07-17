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
 
 Two notifications are observed:
 - changes to network reachability
 - changes to app work mode
 */
class AppContextAwareController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveReachabilityNotification(notification:)), name: AppNotifications.reachabilityChanged.name, object: nil)
        appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveWorkModeNotification(notification:)), name: AppNotifications.workModeChanged.name, object: nil)
        appNotificationCenter.addObserver(self, selector: #selector(AppContextAwareController.recieveLastSyncNotification(notification:)), name: AppNotifications.lastSyncChanged.name, object: nil)
        appReachabilityDidChange()
        appWorkModeDidChange()
    }
    
    @objc func recieveReachabilityNotification(notification: Notification) {
        appReachabilityDidChange()
    }
    
    @objc func recieveWorkModeNotification(notification: Notification) {
        appWorkModeDidChange()
    }
    
    @objc func recieveLastSyncNotification(notification: Notification) {
        appLastSyncDidChange()
    }
    
    func appReachabilityDidChange() {
        
    }
    
    func appWorkModeDidChange() {
        navigationController?.navigationBar.barTintColor = (appContext.workMode == .online) ? appColors.primary : appColors.offline
    }
    
    func appLastSyncDidChange() {

    }
    
    deinit {
        appNotificationCenter.removeObserver(self, name: AppNotifications.reachabilityChanged.name, object: nil)
        appNotificationCenter.removeObserver(self, name: AppNotifications.workModeChanged.name, object: nil)
        appNotificationCenter.removeObserver(self, name: AppNotifications.lastSyncChanged.name, object: nil)
    }
}
