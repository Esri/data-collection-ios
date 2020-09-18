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

class PortalSessionManager {
    
    // MARK:- Portal
    
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
    
    // MARK:- Status
    
    enum Status {
        case none, loading(AGSPortal), loaded(AGSPortal), fallback(AGSPortal, Error), failed(Error)
    }
    
    var status: Status = .none {
        didSet {
            if let portal = portal {
                UserDefaults.standard.set(portal.url, forKey: Self.portalSessionURLKey)
            }
            else {
                UserDefaults.standard.set(nil, forKey: Self.portalSessionURLKey)
            }
            
            delegate?.portalSessionManager(manager: self, didChangeStatus: status)
        }
    }
    
    var isSignedIn: Bool {
        portal?.user != nil
    }
    
    // MARK:- Restore Session
    
    private static let portalSessionURLKey = "\(Bundle.main.bundleIdentifier!).portalSessionManager.urlKey"
    
    func loadSilentCredentialRequiredPortalSession() {
        
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
                print("[Portal Session Manager] Silent Portal -", error.localizedDescription)
                self.status = .none
                self.loadDefaultPortalSession()
            }
            else {
                self.status = .loaded(silentPortal)
            }
        }
    }
    
    // MARK:- Sign In
        
    func loadCredentialRequiredPortalSession() {
        
        if case Status.loading = status { return }
                
        let portal = configuredPortal(loginRequired: true)
        
        status = .loading(portal)

        portal.load { [weak self] (error) in
            guard let self = self else { return }
            
            if let error = error {
                print("[Portal Session Manager]", error.localizedDescription)
                self.fallbackToDefaultPortalSession(previousError: error)
            }
            else {
                self.status = .loaded(portal)
            }
        }
    }
    
    // MARK:- fallbackToDefaultPortalSession
    
    private func fallbackToDefaultPortalSession(previousError: Error) {
        
        guard case Status.loading = status else { return }
        
        let portal = configuredPortal(loginRequired: false)
        
        revokeCredentials {
            
            portal.load { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    print("[Portal Session Manager]", error.localizedDescription)
                    self.status = .failed(error)
                }
                else {
                    self.status = .fallback(portal, previousError)
                }
            }
        }
    }
    
    // MARK:- Sign Out
    
    func loadDefaultPortalSession() {
        
        if case Status.loading = status { return }
        
        let portal = configuredPortal(loginRequired: false)

        status = .loading(portal)
        
        revokeCredentials {
            
            portal.load { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    print("[Portal Session Manager]", error.localizedDescription)
                    self.status = .failed(error)
                }
                else {
                    self.status = .loaded(portal)
                }
            }
        }
    }
        
    // MARK:- Credential
        
    private func revokeCredentials(_ completion: @escaping ()->Void) {
        AGSAuthenticationManager.shared()
            .credentialCache
            .removeAndRevokeAllCredentials { (_) in
                completion()
        }
    }
    
    // MARK:- Init
    
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
