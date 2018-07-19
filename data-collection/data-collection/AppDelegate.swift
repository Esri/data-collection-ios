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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    internal let reachabilityManager: NetworkReachabilityManager = {
        let manager = NetworkReachabilityManager(host: AppConfiguration.basePortalDomain)
        assert(manager != nil, "Network Reachability Manager must be constructed a valid service url.")
        return manager!
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Begin listening to Network Status Changes
        AppDelegate.beginListeningToNetworkStatusChanges()
        
        // Enable credential cache auto sync
        AppDelegate.configCredentialCacheAutoSyncToKeychain()
        
        // Configure oAuth redirect URL
        AppDelegate.configOAuthRedirectURL()
        
        // Set UIAppearance Defaults
        AppDelegate.setAppAppearance()
        
        // Attempt to login from previously stored credentials
        appContext.attemptLoginToPortalFromCredentials()
        
        // Configure file documents directories for offline usage
        FileManager.buildOfflineMapDirectory()
        
        return true
    }
}

extension AppDelegate {
    
    // NOTE: Mostly Nick's Code, URLComponents API has changed in Swift4
    // MARK: OAuth
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle OAuth callback from application(app,url,options) when the app's URL schema is called.
        //
        // See also AppSettings and AppContext.setupAndLoadPortal() to see how the AGSPortal is configured
        // to handle OAuth and call back to this application.
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), urlComponents.scheme == AppConfiguration.urlScheme, urlComponents.host == AppConfiguration.urlAuthPath {
            
            // Pass the OAuth callback through to the ArcGIS Runtime helper function
            AGSApplicationDelegate.shared().application(app, open: url, options: options)
        }
        return true
    }
    
    static func beginListeningToNetworkStatusChanges() {
        
        appDelegate.reachabilityManager.listener = { status in
            print("[Reachability] Network status changed: \(status)")
            appNotificationCenter.post(AppNotifications.reachabilityChanged)
        }
        
        appDelegate.reachabilityManager.startListening()
    }
    
    static func configCredentialCacheAutoSyncToKeychain() {
        AGSAuthenticationManager.shared().credentialCache.enableAutoSyncToKeychain(withIdentifier: AppConfiguration.keychainIdentifier, accessGroup: nil, acrossDevices: false)
    }
    
    static func configOAuthRedirectURL() {
        
        let oauthConfig = AGSOAuthConfiguration(portalURL: AppConfiguration.basePortalURL!,
                                                clientID: AppConfiguration.clientID,
                                                redirectURL: AppConfiguration.oAuthRedirectURLString)
        
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oauthConfig)
    }
}

extension AppDelegate {
    
    static func setAppAppearance() {
        UINavigationBar.appearance().tintColor = appColors.tint
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor : appColors.tint]
        
        UIApplication.shared.statusBarStyle = .lightContent
    }
}

