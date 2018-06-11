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
    
    func dismissAbsolutely(animated: Bool, completion:(() -> Void)?) {
        var toDismiss: UIViewController? = self
        while toDismiss!.presentingViewController != nil {
            toDismiss = toDismiss!.presentingViewController
        }
        toDismiss!.dismiss(animated: animated, completion: completion)
    }
    
    func dismissAfter(_ interval: TimeInterval, animated: Bool, completion:(() -> Void)?) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] (_) in
            self?.dismiss(animated: animated, completion: completion)
        }
    }
}

extension UIViewController {
    
    func present(simpleAlertMessage message: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.simpleAlert(message: message)
        present(alert, animated: animated, completion: completion)
    }

    func present(loginAlertMessage message: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.multiAlert(message: message, actionTitle: "Log in", action: { (action) in
            appContext.login()
        })
        present(alert, animated: animated, completion: completion)
    }

    func present(settingsAlertMessage message: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.multiAlert(message: message, actionTitle: "Settings", action: { [weak self] (action) in
            guard let url = URL(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(url) else {
                self?.present(simpleAlertMessage: "Error opening Settings App.")
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        present(alert, animated: animated, completion: completion)
    }

    // TODO integrate
    func present(confirmationAlertMessage message: String, confirmationTitle: String, confirmationAction:((UIAlertAction)->Void)?, animated: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController.multiAlert(message: message, actionTitle: confirmationTitle, action: confirmationAction)
        present(alert, animated: animated, completion: completion)
    }
}

extension UIViewController {
    
    func addDismissButton(withSelector selector: Selector) {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .done, target: self, action: selector)
    }
    
    func addCancelButton(withSelector selector: Selector) {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: selector)
    }
}
