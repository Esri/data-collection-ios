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

extension UIViewController {
    
    /// Facilitates building and presenting a simple alert message, in one line of code.
    ///
    /// - Parameters:
    ///   - message: The message to display to the end user.
    ///   - animated: Whether the alert animates upon presentation. The default value is true.
    ///   - completion: The call back called by the UIAlertController after presentation has completed. The default value is nil.
    ///
    func present(simpleAlertMessage message: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.simpleAlert(message: message)
        present(alert, animated: animated, completion: completion)
    }

    /// Facilitates building and presenting a simple alert message prompting the user to log-in, in one line of code.
    ///
    /// - Parameters:
    ///   - message: The message to display to the end user.
    ///   - animated: Whether the alert animates upon presentation. The default value is true.
    ///   - completion: The call back called by the UIAlertController after presentation has completed. The default value is nil.
    ///
    func present(loginAlertMessage message: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.multiAlert(message: message, actionTitle: "Log in", action: { (action) in
            appContext.login()
        }, isDestructive: false)
        present(alert, animated: animated, completion: completion)
    }

    /// Facilitates building and presenting a simple alert message prompting the user to modify their settings, in one line of code.
    ///
    /// - Parameters:
    ///   - message: The message to display to the end user.
    ///   - animated: Whether the alert animates upon presentation. The default value is true.
    ///   - completion: The call back called by the UIAlertController after presentation has completed. The default value is nil.
    ///
    func present(settingsAlertMessage message: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.multiAlert(message: message, actionTitle: "Settings", action: { [weak self] (action) in
            guard let url = URL(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(url) else {
                self?.present(simpleAlertMessage: "Error opening Settings App.")
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }, isDestructive: false)
        present(alert, animated: animated, completion: completion)
    }

    /// Facilitates building and presenting a multi alert message prompting the user to confirm an action, in one line of code.
    ///
    /// - Parameters:
    ///   - message: The message to display to the end user.
    ///   - animated: Whether the alert animates upon presentation. The default value is true.
    ///   - completion: The call back called by the UIAlertController after presentation has completed. The default value is nil.
    ///
    func present(confirmationAlertMessage message: String, confirmationTitle: String, confirmationAction:((UIAlertAction)->Void)?, animated: Bool = true, isDestructive: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.multiAlert(message: message, actionTitle: confirmationTitle, action: confirmationAction, isDestructive: true)
        present(alert, animated: animated, completion: completion)
    }
}

