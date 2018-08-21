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

struct AppColors {
    
    let primary: UIColor = UIColor(red:0.66, green:0.81, blue:0.40, alpha:1.00)
    
    let offline: UIColor = .darkGray
    let offlineLight: UIColor = .gray
    let offlineDark: UIColor = .black
    
    let accent: UIColor = UIColor(red:0.93, green:0.54, blue:0.01, alpha:1.00)
    
    let tableCellTitle: UIColor = .gray
    let tableCellValue: UIColor = .black
    
    let invalid: UIColor = .red
    let missing: UIColor = .lightGray
    
    let tint: UIColor = .white
    
    let loginLogoutNormal: UIColor = .white
    let loginLogoutHighlighted: UIColor = .lightGray
    
    let workModeNormal: UIColor = .darkGray
    let workModeHighlighted: UIColor = .lightGray
    let workModeSelected: UIColor = .white
    let workModeDisabled: UIColor = UIColor(white: 0.5, alpha: 0.5)
    
    let offlineActivityNormal: UIColor = .darkGray
    let offlineActivityHighlighted: UIColor = .lightGray
    let offlineActivitySelected: UIColor = .lightGray
    let offlineActivityDisabled: UIColor = UIColor(white: 0.5, alpha: 0.5)
}
