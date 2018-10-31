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

import Foundation
import UIKit.UIColor

// These colors are used throughout the application, when colors are generated at runtime.
extension UIColor {
    
    // MARK: General
    
    // The general of the app and color symbolizing online work mode.
    static let primary = #colorLiteral(red: 0.3783819885, green: 0.6019210188, blue: 0.2394252939, alpha: 1)
    
    // Color symbolizing offline work mode.
    static let offline = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
    
    // Contrasting both primary and offline, bar button items (text and image).
    static let tint = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    
    // Contrasting both primary and offline, used in the drawer.
    static let accent = #colorLiteral(red: 0.8965646404, green: 0.6249603194, blue: 0.0001723665575, alpha: 1)

    // Color symbolizing destructive and invalid.
    static let destructive = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
}

extension AppDelegate {
    
    static func setAppApperanceWithAppColors() {
        
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor : UIColor.tint]
        UINavigationBar.appearance().tintColor = .tint
        
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .tint
        UIButton.appearance().tintColor = .primary
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .primary
        
        UIProgressView.appearance().tintColor = .primary
        UIProgressView.appearance().progressTintColor = .primary
        UIProgressView.appearance().trackTintColor = .tint
        
        UIActivityIndicatorView.appearance().color = .primary
    }
}
