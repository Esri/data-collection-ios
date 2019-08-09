// Copyright 2019 Esri
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

import class UIKit.UIAlertAction

extension UIAlertAction {
    /// Creates a new alert action with "Cancel" as the title and `cancel` as
    /// the style.
    ///
    /// - Parameter handler: A closure to execute when the user selects the
    /// action.
    /// - Returns: A new alert action object.
    class func cancel(handler: ((_ action: UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
    }
    
    /// Creates a new alert action with "OK" as the title and `default` as
    /// the style.
    ///
    /// - Parameter handler: A closure to execute when the user selects the
    /// action.
    /// - Returns: A new alert action object.
    class func okay(handler: ((_ action: UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: "OK", style: .default, handler: handler)
    }
}
