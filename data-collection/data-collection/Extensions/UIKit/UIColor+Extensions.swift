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
    
//    static var houseGreen: UIColor {
//        return UIColor(red:0.66, green:0.81, blue:0.40, alpha:1.00)
//    }
//    
//    static var houseGreenLight: UIColor {
//        return UIColor(red:0.95, green:1.00, blue:0.84, alpha:1.00)
//    }
//    
//    static var houseGreenDark: UIColor {
//        return UIColor(red:0.71, green:0.81, blue:0.55, alpha:1.00)
//    }
//    
//    static var houseOrange: UIColor {
//        return UIColor(red:0.93, green:0.54, blue:0.01, alpha:1.00)
//    }
//    
//    static var houseEdit: UIColor {
//        return .orange
//    }
//    
//    static var houseDelete: UIColor {
//        return .red
//    }
//    
//    static var houseInvalidFormField: UIColor {
//        return UIColor(red:1.00, green:0.94, blue:0.94, alpha:1.00)
//    }
//    
//    static var houseGoodCondition: UIColor {
//        return UIColor(red:0.37, green:0.80, blue:0.24, alpha:1.00)
//    }
//    
//    static var houseFairCondition: UIColor {
//        return UIColor(red:0.91, green:0.83, blue:0.27, alpha:1.00)
//    }
//    
//    static var housePoorCondition: UIColor {
//        return UIColor(red:0.95, green:0.58, blue:0.21, alpha:1.00)
//    }
//    
//    static var houseDeadCondition: UIColor {
//        return UIColor(red:0.92, green:0.27, blue:0.19, alpha:1.00)
//    }
//    
//    static var houseSelectionBackground: UIColor {
//        return UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.00)
//    }
}


extension UIColor {
    
    var lighter: UIColor {
        return addBrightness(0.1)
    }
    
    var darker: UIColor {
        return removeBrightness(0.1)
    }
    
    func removeBrightness(_ val: CGFloat, resultAlpha alpha: CGFloat? = nil) -> UIColor {
        
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return self
        }
        
        return UIColor(hue: h, saturation: s, brightness: max(b - val, 0.0), alpha: (alpha == nil || alpha == -1) ? a : alpha!)
    }
    
    func addBrightness(_ val: CGFloat, resultAlpha alpha: CGFloat? = nil) -> UIColor {
        
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return self
        }
        
        return UIColor(hue: h, saturation: s, brightness: min(b + val, 1.0), alpha: (alpha == nil || alpha == -1) ? a : alpha!)
    }
}
