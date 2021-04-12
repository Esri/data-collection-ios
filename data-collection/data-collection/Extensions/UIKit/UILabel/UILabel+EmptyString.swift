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

extension UILabel {
    
    /// Modify a UILabel representing an empty string to ensure it is not automatically hidden by a `UIStackView`.
    ///
    /// Because a `UIStackView` removes an empty label, this function ensures the empty label remains in place
    /// and from being removed by the stack view by setting its text to a single space.
    
    func considerEmptyString() {
        if text == nil {
            text = " "
        }
        else if let labelText = text, labelText.isEmpty {
            text = " "
        }
    }
}
