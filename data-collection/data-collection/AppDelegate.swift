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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // License the app.
        AppDelegate.licenseApplication()
        
        // Enable credential cache auto sync.
        AppDelegate.configCredentialCacheAutoSyncToKeychain()
        
        // Configure oAuth redirect URL.
        AppDelegate.configOAuthRedirectURL()
        
        // Configure default app colors.
        AppDelegate.setAppApperanceWithAppColors()
        
        return true
    }
}

extension AppDelegate {
    
    // MARK: OAuth
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle OAuth callback from application(app,url,options) when the app's URL schema is called.
        //
        // See also AppSettings and AppContext.setupAndLoadPortal() to see how the AGSPortal is configured
        // to handle OAuth and call back to this application.
        if let redirect = URLComponents(url: url, resolvingAgainstBaseURL: false),
            redirect.scheme == OAuth.components.scheme,
            redirect.host == OAuth.components.host {
            
            // Pass the OAuth callback through to the ArcGIS Runtime SDK's helper function.
            AGSApplicationDelegate.shared().application(app, open: url, options: options)
        }
        return true
    }
    
    static func configCredentialCacheAutoSyncToKeychain() {
        AGSAuthenticationManager.shared().credentialCache.enableAutoSyncToKeychain(
            withIdentifier: .keychainIdentifier,
            accessGroup: nil,
            acrossDevices: false
        )
    }
    
    static func configOAuthRedirectURL() {
        let oauthConfig = AGSOAuthConfiguration(
            portalURL: .basePortal,
            clientID: .clientID,
            redirectURL: OAuth.redirectUrl
        )
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oauthConfig)
    }
}

extension AppDelegate {
    
    /// License the ArcGIS application with the configured ArcGIS Runtime deployment license key.
    ///
    /// - Note: An invalid key does not throw an exception, but simply fails to license the app,
    ///   falling back to Developer Mode (which will display a watermark on the map view).
    static func licenseApplication() {
        do {
            try AGSArcGISRuntimeEnvironment.setLicenseKey(.licenseKey)
        } catch {
            print("[Error: AGSArcGISRuntimeEnvironment] Error licensing app: \(error.localizedDescription)")
        }
        print("[ArcGIS Runtime License] \(AGSArcGISRuntimeEnvironment.license())")
    }
}
