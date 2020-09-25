// Copyright 2020 Esri
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

import ArcGIS

protocol PortalSessionManagerDelegate: class {
    func portalSessionManager(manager: PortalSessionManager, didChangeStatus status: PortalSessionManager.Status)
}

/// The `PortalSessionManager` is responsible for managing the active portal session.
///
/// The `AppContext.WorkMode.online` case depends on a loaded portal session.
/// The portal session does not necessarily require user authentication,
/// allowing the web map's sharing permissions to drive whether to issue an authentication challenge.
/// The `PortalSessionManager` uses a state-machine design pattern to maintain an active portal session and
/// the delegate pattern to report changes of state back to the `AppContext`.
/// The `PortalSessionManager` strives to maintain an active portal session,
/// even attempting to silently load a restored from a previous session upon app relaunch.
///
class PortalSessionManager {
    
    // MARK: Status
    
    enum Status {
        case none, loading(AGSPortal), loaded(AGSPortal), fallback(AGSPortal, Error), failed(Error)
    }
    
    var status: Status = .none {
        didSet {
            
            switch status {
            case .none:
                print(
                    "[Portal Session Manager]",
                    "\n\tNo portal"
                )
                break
            case .loading(let portal):
                print(
                    "[Portal Session Manager]",
                    "\n\tLoading Portal -", portal.url?.absoluteString ?? "(missing)"
                )
            case .loaded(let portal):
                print(
                    "[Portal Session Manager]",
                    "\n\tLoaded Portal -", portal.url?.absoluteString ?? "(missing)",
                    "\n\tUser -", portal.user?.username ?? "(no user)"
                )
            case .fallback(let portal, let error):
                print(
                    "[Portal Session Manager]",
                    "\n\tFallback -", error.localizedDescription,
                    "\n\tPortal -", portal.url?.absoluteString ?? "(missing)",
                    "\n\tUser -", portal.user?.username ?? "(no user)"
                )
            case .failed(let error):
                print(
                    "[Portal Session Manager]",
                    "\n\tFailed -", error.localizedDescription
                )
            }
            
            if let portal = portal {
                UserDefaults.standard.set(portal.url, forKey: Self.portalSessionURLKey)
            }
            else {
                UserDefaults.standard.set(nil, forKey: Self.portalSessionURLKey)
            }
            
            delegate?.portalSessionManager(manager: self, didChangeStatus: status)
        }
    }
    
    // MARK: Portal
    
    var portal: AGSPortal? {
        switch status {
        case .loaded(let portal):
            return portal
        case .fallback(let portal, _):
            return portal
        default:
            return nil
        }
    }
    
    var error: Error? {
        switch status {
        case .fallback(_, let error):
            return error
        case .failed(let error):
            return error
        default:
            return nil
        }
    }
    
    var isSignedIn: Bool {
        portal?.user != nil
    }
    
    // MARK: Restore Session
    
    private static let portalSessionURLKey = "\(Bundle.main.bundleIdentifier!).portalSessionManager.urlKey"
    
    func silentlyLoadCredentialRequiredPortalSession() {
        
        if case Status.loading = status { return }
        
        guard let url = UserDefaults.standard.url(forKey: Self.portalSessionURLKey) else {
            loadDefaultPortalSession()
            return
        }
        
        let silentPortal = AGSPortal(url: url, loginRequired: true)
        
        status = .loading(silentPortal)
        
        let originalRequestConfiguration = silentPortal.requestConfiguration
        
        var silentRequestConfiguration: AGSRequestConfiguration?
        if let configuration = originalRequestConfiguration {
            silentRequestConfiguration = configuration.copy() as? AGSRequestConfiguration
        }
        else {
            silentRequestConfiguration = AGSRequestConfiguration.global().copy() as? AGSRequestConfiguration
        }
        
        silentRequestConfiguration?.shouldIssueAuthenticationChallenge = { _ in return false }
        
        silentPortal.requestConfiguration = silentRequestConfiguration
        silentPortal.load() { [weak self] error in
            guard let self = self else { return }
            silentPortal.requestConfiguration = originalRequestConfiguration
            
            if let error = error {
                print(
                    "[Portal Session Manager]",
                    "\n\tSilent Portal Failed -", error.localizedDescription
                )
                self.status = .none
                self.loadDefaultPortalSession()
            }
            else {
                self.status = .loaded(silentPortal)
            }
        }
    }
    
    // MARK: Sign In
        
    func loadCredentialRequiredPortalSession() {
        
        if case Status.loading = status { return }
                
        let portal = configuredPortal(loginRequired: true)
        
        status = .loading(portal)

        portal.load { [weak self] (error) in
            guard let self = self else { return }
            
            if let error = error {
                self.fallbackToDefaultPortalSession(previousError: error)
            }
            else {
                self.status = .loaded(portal)
            }
        }
    }
    
    // MARK: Fallback Portal
    
    private func fallbackToDefaultPortalSession(previousError: Error) {
        
        guard case Status.loading = status else { return }
        
        let portal = configuredPortal(loginRequired: false)
        
        revokeCredentials {
            
            portal.load { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    self.status = .failed(error)
                }
                else {
                    self.status = .fallback(portal, previousError)
                }
            }
        }
    }
    
    // MARK: Sign Out
    
    func loadDefaultPortalSession() {
        
        if case Status.loading = status { return }
        
        let portal = configuredPortal(loginRequired: false)

        status = .loading(portal)
        
        revokeCredentials {
            
            portal.load { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    self.status = .failed(error)
                }
                else {
                    self.status = .loaded(portal)
                }
            }
        }
    }
        
    // MARK: Credential
        
    private func revokeCredentials(_ completion: @escaping ()->Void) {
        AGSAuthenticationManager.shared()
            .credentialCache
            .removeAndRevokeAllCredentials { (_) in
                completion()
        }
    }
    
    // MARK: Init
    
    private let url: URL
        
    private func configuredPortal(loginRequired: Bool) -> AGSPortal {
        AGSPortal(url: url, loginRequired: loginRequired)
    }
    
    init(portal url: URL) {
        self.url = url
    }
    
    // MARK:- Delegate
    
    weak var delegate: PortalSessionManagerDelegate?
}
