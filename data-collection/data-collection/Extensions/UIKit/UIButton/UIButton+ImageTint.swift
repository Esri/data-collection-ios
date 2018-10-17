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
import UIKit

extension UIButton {
    
    /// Generate a single image to be used as a color mask for a button's image and set a new button image as apprpopriate
    /// for every (control state, color) combo.
    ///
    /// - Parameters:
    ///   - controlStateColors: A dictionary of control states (keys) and their cooresponding colors (values).
    ///   - controlState: The control state containing the mask image, default value is `.normal`.
    func buildImagesWithTintColors(forControlStateColors controlStateColors: [UIControl.State: UIColor], fromControlStateImage controlState: UIControl.State = .normal) {
        
        guard let normalImage = image(for: controlState) else {
            print("[Tint Color Error] no default image for control state: \(controlState).")
            return
        }
        
        controlStateColors.forEach { (state, color) in
            setImage(normalImage.renderImage(toMaskWithColor: color), for: state)
        }
    }
}
