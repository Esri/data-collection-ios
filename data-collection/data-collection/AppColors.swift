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
    
    static let primary: UIColor = #colorLiteral(red:0.66, green:0.81, blue:0.40, alpha:1.00)
    
    static let offline: UIColor = .darkGray
    
    static let accent: UIColor = #colorLiteral(red:0.97, green:0.74, blue:0.18, alpha:1.00)
    
    static let tableCellTitle: UIColor = .gray
    static let tableCellValue: UIColor = .black
    
    static let invalid: UIColor = .red
    static let missing: UIColor = .lightGray
    
    static let tint: UIColor = .white
    
    static let loginLogoutNormal: UIColor = .white
    static let loginLogoutHighlighted: UIColor = .lightGray
    
    static let workModeNormal: UIColor = .darkGray
    static let workModeHighlighted: UIColor = .lightGray
    static let workModeSelected: UIColor = .white
    static let workModeDisabled: UIColor = UIColor(white: 0.5, alpha: 0.5)
    
    static let offlineActivityNormal: UIColor = .darkGray
    static let offlineActivityHighlighted: UIColor = .lightGray
    static let offlineActivitySelected: UIColor = .lightGray
    static let offlineActivityDisabled: UIColor = UIColor(white: 0.5, alpha: 0.5)
}
