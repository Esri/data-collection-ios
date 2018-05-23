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

protocol StringInitializable {
    init?(fromString string: String)
}

protocol IntegerType: StringInitializable { }

extension Int: IntegerType {
    init?(fromString string: String) {
        guard let int = Int(string) else {
            return nil
        }
        self = int
    }
}

extension Int8: IntegerType {
    init?(fromString string: String) {
        guard let int = Int8(string) else {
            return nil
        }
        self = int
    }
}

extension Int16: IntegerType {
    init?(fromString string: String) {
        guard let int = Int16(string) else {
            return nil
        }
        self = int
    }
}

extension Int32: IntegerType {
    init?(fromString string: String) {
        guard let int = Int32(string) else {
            return nil
        }
        self = int
    }
}

extension Int64: IntegerType {
    init?(fromString string: String) {
        guard let int = Int64(string) else {
            return nil
        }
        self = int
    }
}

final class PopupIntegerCell: PopupTextFieldCell<IntegerType> {
    
    override var keyboardType: UIKeyboardType {
        return .numberPad
    }
}
