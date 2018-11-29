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
    
    /// Build and present a simple alert message.
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

    /// Build and present a simple alert message prompting the user to log-in.
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

    /// Build and present a simple alert message prompting the user to modify their settings.
    ///
    /// - Parameters:
    ///   - message: The message to display to the end user.
    ///   - animated: Whether the alert animates upon presentation. The default value is true.
    ///   - completion: The call back called by the UIAlertController after presentation has completed. The default value is nil.
    ///
    func present(settingsAlertMessage message: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.multiAlert(message: message, actionTitle: "Settings", action: { [weak self] (action) in
            guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else {
                self?.present(simpleAlertMessage: "Error opening Settings App.")
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }, isDestructive: false)
        present(alert, animated: animated, completion: completion)
    }

    /// Build and present a multi alert message prompting the user to confirm an action.
    ///
    /// - Parameters:
    ///   - message: The message to display to the end user.
    ///   - animated: Whether the alert animates upon presentation. The default value is true.
    ///   - completion: The call back called by the UIAlertController after presentation has completed. The default value is nil.
    ///
    func present(confirmationAlertMessage message: String, confirmationTitle: String, isDestructive: Bool = true, confirmationAction:((UIAlertAction)->Void)?, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.multiAlert(message: message, actionTitle: confirmationTitle, action: confirmationAction, isDestructive: isDestructive)
        present(alert, animated: animated, completion: completion)
    }
}
