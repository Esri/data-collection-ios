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
    
    func buildImagesWithTintColors(forControlStateColors controlStateColors: [UIControlState: UIColor], fromControlStateImage controlState: UIControlState = .normal) {
        
        guard let normalImage = image(for: controlState) else {
            print("[Tint Color Error] no default image for control state normal.")
            return
        }
        
        for controlStateColor in controlStateColors {
            if let controlStateImage = normalImage.renderImage(toMaskWithColor: controlStateColor.value) {
                setImage(controlStateImage, for: controlStateColor.key)
            }
        }
    }
}
