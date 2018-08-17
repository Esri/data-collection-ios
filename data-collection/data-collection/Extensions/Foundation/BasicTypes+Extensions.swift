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

import CoreGraphics
import Foundation

extension Bool {
    
    var asAlpha: CGFloat {
        get {
            return self ? CGFloat(1.0) : CGFloat(0.0)
        }
    }
    
    var asAlphaDimmed: CGFloat {
        get {
            return !self ? CGFloat(1.0) : CGFloat(0.6)
        }
    }
}

extension CGFloat {
    
    var asBool: Bool {
        get {
            return self == 1.0
        }
    }
}

extension Double {
    
    var asRadians: Double {
        return (self / 180.0) * .pi
    }
}

extension Date {
    
    var mediumDateFormatted: String {
        return DateFormatter.format(mediumDate: self)
    }
    
    var shortDateTimeFormatted: String {
        return DateFormatter.format(shortDateTime: self)
    }
}

extension String {
    
    func removeCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }
    
    func removeCharacters(from: String) -> String {
        return removeCharacters(from: CharacterSet(charactersIn: from))
    }
}
