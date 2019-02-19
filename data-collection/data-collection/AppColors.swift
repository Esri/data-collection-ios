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
    static let primary = UIColor(named: "primary")!
    
    // Color symbolizing offline work mode.
    static let offline = UIColor(named: "offline")!
    
    // Contrasting both primary and offline, bar button items (text and image).
    static let tint = UIColor(named: "tint")!
    
    // Contrasting both primary and offline, used in the drawer.
    static let accent = UIColor(named: "accent")!

    // Color symbolizing destructive and invalid.
    static var destructive = UIColor(named: "destructive")!
}

extension AppDelegate {
    
    static func setAppApperanceWithAppColors() {
        
        // Non-app specific navigation controllers bar button items.
        // This includes: `UIImagePickerViewController`, `QLPreviewController`
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationController.self]).tintColor = .primary
        
        // App specific navigation controllers.
        // This includes any navigation controller found in app project storyboards.
        UINavigationBar.appearance(whenContainedInInstancesOf: [AppContextAwareNavigationController.self]).titleTextAttributes = [.foregroundColor : UIColor.tint]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self, AppContextAwareNavigationController.self]).tintColor = .tint
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = .primary
        
        UIButton.appearance(whenContainedInInstancesOf: [UITableView.self]).tintColor = .primary

        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .primary
        
        UIProgressView.appearance().tintColor = .primary
        UIProgressView.appearance().progressTintColor = .primary
        UIProgressView.appearance().trackTintColor = .tint
        
        UIActivityIndicatorView.appearance().color = .primary
        
        UISegmentedControl.appearance().tintColor = .primary
        
        StyledFirstResponderLabel.appearance().tintColor = .primary
    }
}
