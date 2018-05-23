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

protocol FloatType: StringInitializable {}

extension Float: FloatType {
    init?(fromString string: String) {
        guard let float = Float(string) else {
            return nil
        }
        self = float
    }
}

extension Double: FloatType {
    init?(fromString string: String) {
        guard let float = Double(string) else {
            return nil
        }
        self = float
    }
}

final class PopupFloatCell: PopupTextFieldCell<FloatType> {
    
    override var keyboardType: UIKeyboardType {
        return .decimalPad
    }
}
