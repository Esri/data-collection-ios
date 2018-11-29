//// Copyright 2017 Esri
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

extension UIColor {
    
    /// Make a slightly "lighter" version of the color.
    ///
    /// - Note: This function will not work with sRGB color space.
    var lighter: UIColor {
        return addBrightness(0.1)
    }
    
    /// Make a slightly "darker" version of the color.
    ///
    /// - Note: This function will not work with sRGB color space.
    var darker: UIColor {
        return removeBrightness(0.1)
    }
    
    /// Generate a new color by reducing the brightness in HSB.
    ///
    /// - Note: This function will not work with sRGB color space.
    ///
    /// - Parameters:
    ///   - val: By how much to reduce the brightness.
    ///   - alpha: Specifies the resulting color's alpha value (optional).
    ///
    /// - Returns: A new `UIColor`.
    
    func removeBrightness(_ val: CGFloat, resultAlpha alpha: CGFloat? = nil) -> UIColor {
        
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return self
        }
        
        return UIColor(hue: h, saturation: s, brightness: max(b - val, 0.0), alpha: (alpha == nil || alpha == -1) ? a : alpha!)
    }
    
    /// Generate a new color by increasing the brightness in HSB.
    ///
    /// - Note: This function will not work with sRGB color space.
    ///
    /// - Parameters:
    ///   - val: By how much to increase the brightness.
    ///   - alpha: Specifies the resulting color's alpha value (optional).
    ///
    /// - Returns: A new `UIColor`.
    
    func addBrightness(_ val: CGFloat, resultAlpha alpha: CGFloat? = nil) -> UIColor {
        
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return self
        }
        
        return UIColor(hue: h, saturation: s, brightness: min(b + val, 1.0), alpha: (alpha == nil || alpha == -1) ? a : alpha!)
    }
}
