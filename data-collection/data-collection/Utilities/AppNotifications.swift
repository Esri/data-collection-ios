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

protocol AppNotification {
    static var name: String { get }
}

extension AppNotification {
    static var notification: Notification {
        return Notification(name: Notification.Name(rawValue: "\(appBundleID).notifications.name.\(name)"))
    }
}

class AppNotifications {
    
    static var reachabilityChanged: Notification {
        return ReachabilityChanged.notification
    }
    
    static var workModeChanged: Notification {
        return WorkModeChanged.notification
    }
    
    static var lastSyncChanged: Notification {
        return LastSyncChanged.notification
    }
}

fileprivate struct ReachabilityChanged: AppNotification {
    static var name = "reachabilityChanged"
}

fileprivate struct WorkModeChanged: AppNotification {
    static var name = "workModeChanged"
}

fileprivate struct LastSyncChanged: AppNotification {
    static var name = "lastSyncChanged"
}
