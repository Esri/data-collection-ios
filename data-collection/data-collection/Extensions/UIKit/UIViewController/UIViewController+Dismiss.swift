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
    
    /// Dismiss the view controller after a time interval.
    ///
    /// - Parameters:
    ///   - interval: The `TimeInterval` to wait before the view controller is dismissed.
    ///   - animated: If the view controller should animate it's dismissal.
    ///   - completion: A closure that is performed upon completion of the view controller's dismissal.
    ///
    func dismissAfter(_ interval: TimeInterval, animated: Bool, completion:(() -> Void)?) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] (_) in
            self?.dismiss(animated: animated, completion: completion)
        }
    }
    
    func popDismiss(animated: Bool, completion: (() -> Void)? = nil) {
        
        if let navigationController = navigationController {
            
            if isRootViewController {
                dismiss(animated: animated, completion: completion)
            }
            else {
                navigationController.popViewController(animated: animated)
            }
        }
        else {
            dismiss(animated: animated, completion: completion)
        }
    }
}
