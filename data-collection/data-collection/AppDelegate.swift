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
        
        // Attempt to sign in from previously stored credentials.
        appContext.portalSession.silentlyLoadCredentialRequiredPortalSession()
        
        // Load offline map, if one exists.
        appContext.offlineMapManager.loadOfflineMobileMapPackage()
        
        return true
    }
}

// MARK:- OAuth

extension AppDelegate {
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle OAuth callback from application(app,url,options) when the app's URL schema is called.
        //
        // See also AppSettings and AppContext.setupAndLoadPortal() to see how the AGSPortal is configured
        // to handle OAuth and call back to this application.
        if let redirect = URLComponents(url: url, resolvingAgainstBaseURL: false),
            redirect.scheme == OAuthConfig.components.scheme,
            redirect.host == OAuthConfig.components.host {
            
            // Pass the OAuth callback through to the ArcGIS Runtime SDK's helper function.
            AGSApplicationDelegate.shared().application(app, open: url, options: options)
            
            appContext.portalSession.silentlyLoadCredentialRequiredPortalSession()
        }
        return true
    }
    
    static func configCredentialCacheAutoSyncToKeychain() {
        AGSAuthenticationManager.shared().credentialCache.enableAutoSyncToKeychain(
            withIdentifier: "\(Bundle.main.bundleIdentifier!).keychain",
            accessGroup: nil,
            acrossDevices: false
        )
    }
    
    static func configOAuthRedirectURL() {
        let oauthConfig = AGSOAuthConfiguration(
            portalURL: .basePortal,
            clientID: .clientID,
            redirectURL: OAuthConfig.redirectUrl
        )
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oauthConfig)
    }
}

// MARK:- ArcGIS License

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

extension AGSLicense {
    open override var description: String {
        guard self.licenseType != .developer else {
            // We just return the type, since type and level would both be Developer, which is redundant
            return "\(self.licenseType)"
        }
        
        return "\(self.licenseLevel) [\(self.licenseType), \(self.statusAndExpiryDescription)]"
    }
    
    private var statusAndExpiryDescription: String {
        if let expirationDate = self.expiryNilledForLicenseLevel {
            switch self.licenseStatus {
            case .valid:
                // Valid until some time in the future…
                return "\(self.licenseStatus) Until \(expirationDate)"
            case .loginRequired:
                // Don't know what expiry is in this case, so we'll assume it's provided.
                fallthrough
            case .expired:
                // Expired some time back…
                return "\(self.licenseStatus) (Expired \(expirationDate))"
            case .invalid:
                // Not a valid license. Expiration means nothing.
                return "\(self.licenseStatus)"
            @unknown default:
                fatalError("Unsupported case \(self).")
            }
        } else {
            // No expiry…
            switch self.licenseStatus {
            case .valid:
                return "\(self.licenseStatus) Indefinitely"
            default:
                return "\(self.licenseStatus)"
            }
        }
    }
    
    private var expiryNilledForLicenseLevel: Date? {
        if self.licenseLevel == .developer && self.expiry?.timeIntervalSince1970 == 0 ||
            self.licenseLevel == .lite && (self.expiry ?? Date.distantFuture) == Date.distantFuture {
            return nil
        }
        return self.expiry
    }
}

extension AGSLicenseLevel : CustomStringConvertible {
    public var description: String {
        switch self {
        case .developer:
            return "Developer"
        case .lite:
            return "Lite"
        case .basic:
            return "Basic"
        case .standard:
            return "Standard"
        case .advanced:
            return "Advanced"
        @unknown default:
            fatalError("Unsupported case \(self).")
        }
    }
}

extension AGSLicenseStatus : CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid:
            return "Invalid"
        case .valid:
            return "Valid"
        case .expired:
            return "Expired"
        case .loginRequired:
            return "Login Required"
        @unknown default:
            fatalError("Unsupported case \(self).")
        }
    }
}

extension AGSLicenseType : CustomStringConvertible {
    public var description: String {
        switch self {
        case .developer:
            return "Developer (not suitable for production deployment)"
        case .namedUser:
            return "Named User"
        case .licenseKey:
            return "License Key"
        @unknown default:
            fatalError("Unsupported case \(self).")
        }
    }
}
