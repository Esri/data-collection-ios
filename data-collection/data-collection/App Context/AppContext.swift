//// Copyright 2017 Esri
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

let appContext = AppContext()

/// The `AppContext` maintains the app's current state.
///
/// Primarily, the `AppContext` is responsible for:
/// * Authentication and user lifecyle management.
/// * Loading AGSMaps from an AGSPortal or an offline AGSMobileMapPackage.
/// * Managing online and offline work modes.

class AppContext: NSObject {
    
    override init() {
        
        let defaultWorkMode: WorkMode = .retrieveDefaultWorkMode()
        
        switch defaultWorkMode {
        case .online, .offline:
            workMode = defaultWorkMode
        default:
            workMode = .online(nil)
        }
        
        super.init()
        
        locationManager.delegate = self
        portalSession.delegate = self
        offlineMapManager.delegate = self
    }
    
    // MARK: Locator
    
    let addressLocator = AddressLocator()
    
    // MARK: Location Manger
    
    private let locationManager = CLLocationManager()
    
    var locationAuthorized: Bool {
        let status = CLLocationManager.authorizationStatus()
        return
            status == .authorizedWhenInUse ||
            status == .authorizedAlways ||
            status == .notDetermined
    }
    
    // MARK: Portal Session Manager
    
    let portalSession = PortalSessionManager(portal: .basePortal)
    
    // MARK: Portal Session
    
    /// Trigger a sign-in sequence to a portal by building a portal where `loginRequired` is `true`.
    ///
    /// - Note: The ArcGIS Runtime SDK will present a modal sign-in web view if it cannot find any suitable cached credentials.
    func signIn() {
        portalSession.loadCredentialRequiredPortalSession()
    }
    
    /// Log out in the app and from the portal.
    ///
    /// The app does this by removing all cached credentials and no longer requiring authentication in the portal.
    func signOut() {
        addressLocator.removeCredentialsFromServices()
        portalSession.loadDefaultPortalSession()
    }
    
    // MARK: Offline Map Manager
    
    let offlineMapManager = OfflineMapManager(webmap: .webMapItemID)
    
    // MARK:- Work Mode
    
    /// The app's current work mode.
    ///
    /// This property is initialized with the work mode from the user's last session.
    ///
    /// - Note: The app can have an offline map even when working online.
    var workMode: WorkMode {
        didSet {
            workMode.storeDefaultWorkMode()
            NotificationCenter.default.post(workModeDidChange)
        }
    }
    
    func setWorkModeOnline() {
        if let portal = portalSession.portal {
            workMode = .online(portal.configuredMap)
        }
        else {
            workMode = .none
        }
        
    }
    
    func setWorkModeOffline() throws {
        switch offlineMapManager.status {
        case .none, .failed(_):
            throw OfflineMapManager.MissingOfflineMapError()
        case .loading(_):
            workMode = .offline(nil)
        case .loaded(_, let map):
            workMode = .offline(map)
        }
    }
    
    func deleteOfflineMapAndAttemptToGoOnline() {
        
        offlineMapManager.deleteOfflineMap()

        if let portal = portalSession.portal {
            let map = portal.configuredMap
            map.load(completion: nil)
            workMode = .online(map)
        }
        else {
            workMode = .online(nil)
            portalSession.silentlyLoadCredentialRequiredPortalSession()
        }
    }
    
    // MARK: Map

    var currentMap: AGSMap? {
        switch workMode {
        case .none:
            return nil
        case .online(let map):
            return map
        case .offline(let map):
            return map
        }
    }
    
    var isCurrentMapLoaded: Bool {
        return currentMap?.loadStatus == .loaded
    }
}

private extension String {
    static let userDefaultsWorkModeKey = "WorkMode.\(String.webMapItemID)"
}

// MARK:- Location Manager Delegate

extension AppContext: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print(
            "[Location Manager]",
            "\n\tStatus - \(status)"
        )
        NotificationCenter.default.post(locationAuthorizationNotification)
    }
}

// MARK:- Portal Session Manager Delegate

extension AppContext: PortalSessionManagerDelegate {
    
    func portalSessionManager(manager: PortalSessionManager, didChangeStatus status: PortalSessionManager.Status) {

        NotificationCenter.default.post(portalDidChange)
        
        guard case .online = workMode else { return }
        
        switch status {
        case .loaded(let portal), .fallback(let portal, _):
            let map = portal.configuredMap
            map.load(completion: nil)
            workMode = .online(map)
        case .failed:
            workMode = .online(nil)
        default:
            break
        }
    }
}

// MARK:- Offline Map Manager Delegate

extension AppContext: OfflineMapManagerDelegate {
    
    func offlineMapManager(_ manager: OfflineMapManager, didUpdateLastSync date: Date?) {
        NotificationCenter.default.post(offlineMapDidChange)
    }
    
    func offlineMapManager(_ manager: OfflineMapManager, didUpdate status: OfflineMapManager.Status) {
        NotificationCenter.default.post(offlineMapDidChange)
        if case .offline = workMode, case let .loaded(_, managedOfflineMap) = status {
            workMode = .offline(managedOfflineMap)
        }
    }
    
    func offlineMapManager(_ manager: OfflineMapManager, didFinishJob result: Result<JobResult, Error>) {
        if case let .success(jobResult) = result, jobResult is AGSGenerateOfflineMapResult {
            workMode = .offline(nil)
            offlineMapManager.loadOfflineMobileMapPackage()
        }
        else if case let .success(jobResult) = result, let syncJobResult = jobResult as? AGSOfflineMapSyncResult {
            if syncJobResult.isMobileMapPackageReopenRequired {
                offlineMapManager.loadOfflineMobileMapPackage()
            }
        }
    }
}

// MARK:- Notification Center

extension Notification.Name {
    static let portalDidChange = Notification.Name("portalDidChange")
    static let workModeDidChange = Notification.Name("workModeDidChange")
    static let offlineMapDidChange = Notification.Name("offlineMapDidChange")
    static let locationAuthorizationDidChange = Notification.Name("locationAuthorizationDidChange")
}

extension AppContext {
    
    var portalDidChange: Notification {
        Notification(
            name: .portalDidChange,
            object: self,
            userInfo: nil
        )
    }
    
    var workModeDidChange: Notification {
        Notification(
            name: .workModeDidChange,
            object: self,
            userInfo: nil
        )
    }
    
    var offlineMapDidChange: Notification {
        Notification(
            name: .offlineMapDidChange,
            object: self,
            userInfo: nil
        )
    }
    
    var locationAuthorizationNotification: Notification {
        Notification(
            name: .locationAuthorizationDidChange,
            object: self,
            userInfo: nil
        )
    }
}

extension AppContext {
    
    enum WorkMode {
        
        case none
        /// This case is only set with a nil map when retrieved from `UserDefaults` or because a resource is loading.
        /// Otherwise, the AppContext will set `.none`.
        case online(AGSMap?), offline(AGSMap?)
                
        func storeDefaultWorkMode() {
            UserDefaults.standard.set(userDefault, forKey: .userDefaultsWorkModeKey)
        }
        
        private var userDefault: String {
            switch self {
            case .none:
                return "none"
            case .online(_):
                return "online"
            case .offline(_):
                return "offline"
            }
        }
        
        static func retrieveDefaultWorkMode() -> WorkMode {
            if let stored = UserDefaults.standard.string(forKey: .userDefaultsWorkModeKey) {
                switch stored {
                case "none":
                    return .none
                case "online":
                    return .online(nil)
                case "offline":
                    return .offline(nil)
                default:
                    return .none
                }
            }
            else {
                return .none
            }
        }
    }
}

extension CLAuthorizationStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .authorizedAlways:
            return "Authorized Always"
        case .authorizedWhenInUse:
            return "Authorized When In-Use"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        @unknown default:
            fatalError("Unsupported case \(self).")
        }
    }
}
