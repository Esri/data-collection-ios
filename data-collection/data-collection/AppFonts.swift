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
import UIKit.UIFont

// These fonts are used throughout the application, when fonts are generated at runtime.
extension UIFont {
    
    static var tableCellTitle: UIFont {
        return UIFont.preferredFont(forTextStyle: .footnote)
    }
    
    static var tableCellValue: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }
    
    static let drawerButtonHeader = UIFont.systemFont(ofSize: 15.0)
    
    static let drawerButtonSubheader = UIFont.systemFont(ofSize: 12.0)
}
