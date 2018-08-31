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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // License the app
        AppDelegate.licenseApplication()
        
        // Reachability
        appReachability.resetAndStartListening()
        
        // Enable credential cache auto sync
        AppDelegate.configCredentialCacheAutoSyncToKeychain()
        
        // Configure oAuth redirect URL
        AppDelegate.configOAuthRedirectURL()
        
        // Attempt to login from previously stored credentials
        appContext.attemptLoginToPortalFromCredentials()
        
        // Configure file documents directories for offline usage
        FileManager.buildOfflineMapDirectory()

        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        appReachability.resetAndStartListening()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        appReachability.stopListening()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        appReachability.stopListening()
    }
}

extension AppDelegate {
    
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
    
    static func configCredentialCacheAutoSyncToKeychain() {
        AGSAuthenticationManager.shared().credentialCache.enableAutoSyncToKeychain(withIdentifier: AppConfiguration.keychainIdentifier, accessGroup: nil, acrossDevices: false)
    }
    
    static func configOAuthRedirectURL() {
        
        let oauthConfig = AGSOAuthConfiguration(portalURL: AppConfiguration.basePortalURL,
                                                clientID: AppConfiguration.clientID,
                                                redirectURL: AppConfiguration.oAuthRedirectURLString)
        
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oauthConfig)
    }
}

extension AppDelegate {
    
    static func licenseApplication() {
        
        do {
            try AGSArcGISRuntimeEnvironment.setLicenseKey(AppConfiguration.licenseKey)
        } catch {
            print("Error licensing app: \(error.localizedDescription)")
        }
        
        print("[ArcGIS Runtime License] \(AGSArcGISRuntimeEnvironment.license())")
    }
}
