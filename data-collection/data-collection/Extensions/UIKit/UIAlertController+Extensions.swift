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
    
    static func simpleAlert(title:String? = nil, message:String, actionTitle:String = "OK", action:((UIAlertAction)->Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default, handler: action)
        alert.addAction(action)
        return alert
    }
    
    static func multiAlert(title:String? = nil, message:String, actionTitle:String, action:((UIAlertAction)->Void)? = nil, isDestructive: Bool = false, cancelTitle:String = "Cancel", cancel:((UIAlertAction)->Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: isDestructive ? .destructive : .default, handler: action)
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel, handler: cancel)
        alert.addAction(action)
        alert.addAction(cancel)
        return alert
    }
}
