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

extension UIControlState: Hashable {

    public var hashValue: Int {
        return Int(rawValue)
    }
}

extension UIButton {
    
    func setTintColors(forControlStateColors controlStateColors: [UIControlState: UIColor]) {

        guard let normalImage = image(for: .normal) else {
            print("[Tint Color Error] no default image for control state normal.")
            return
        }
        setImage(normalImage, forControlStateColors: controlStateColors)
    }

    func setImage(_ image: UIImage, forControlStateColors controlStateColors: [UIControlState: UIColor]) {

        for controlStateColor in controlStateColors {
            if let controlStateImage = image.renderImage(toMaskWithColor: controlStateColor.value) {
                setImage(controlStateImage, for: controlStateColor.key)
            }
        }
    }
}

