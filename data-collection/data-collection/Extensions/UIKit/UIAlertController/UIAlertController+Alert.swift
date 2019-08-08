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

extension UIAlertController {
    
    /// Build a single button `UIAlertController` with a message.
    ///
    /// You may optionally provide additional parameters including the title and an action closure.
    ///
    /// - Parameters:
    ///   - title: The title of the alert (optional).
    ///   - message: The message body of the alert.
    ///   - action: A closure triggered upon tapping the action button (optional).
    ///
    /// - Returns: A newly created and configured single button `UIAlertController` of style `.alert`.
    static func simpleAlert(title: String? = nil, message: String, action: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction.okay(handler: action)
        alert.addAction(action)
        alert.preferredAction = action
        return alert
    }
    
    /// Build a two-button `UIAlertController` with a message.
    ///
    /// The alert contains an action button and a cancel button, by default.
    ///
    /// - Parameters:
    ///   - title: The title of the alert (optional).
    ///   - message: The message body of the alert.
    ///   - actionTitle: The title of the alert's action button.
    ///   - action: A closure triggered upon tapping the action button (optional).
    ///   - isDestructive: A `Bool` specifiying if the action button should be configured as destructive (optional), the default value is `false`.
    ///   - cancel: A closure triggered upon tapping the cancel button (optional).
    ///
    /// - Returns: A newly created and configured two-button button `UIAlertController` of style `.alert`.
    static func multiAlert(title: String? = nil, message: String, actionTitle: String, action: ((UIAlertAction) -> Void)? = nil, isDestructive: Bool = false, cancel cancelHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: isDestructive ? .destructive : .default, handler: action)
        alert.addAction(action)
        alert.preferredAction = action
        alert.addAction(.cancel(handler: cancelHandler))
        return alert
    }
}
