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

extension CGFloat {
    
    /// Builds a `CGFloat` from `true` or `false`.
    ///
    /// * `true` produces a value of 1.0
    /// * `false` produces a value of 0.0
    ///
    /// - Parameter bool: The value you would like to convert.
    ///
    /// - Note: This can be used to convert a `Bool` to a Core Graphics usable float value where the range of
    /// animatable values are between 0.0 and 1.0, for example, `alpha`.
    
    init(_ bool: Bool) {
        self = bool ? 1.0 : 0.0
    }
}

extension CGFloat {
    
    /// Facilitates converting degree value to it's cooresponding radian value.
    
    var degreeToRadian: CGFloat {
        return (self / 180.0) * .pi
    }
}
