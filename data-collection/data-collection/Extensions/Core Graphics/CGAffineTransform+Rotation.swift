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

extension CGAffineTransform {
    
    /// Builds a new `CGAffineTransform` from degress, rather than radians.
    ///
    /// - Parameter degree: The degree value to be made into a `CGAffineTransform`.
    
    init(rotationDegree degree: Double) {
        // Because of how `CGAffineTransform` is used differently by iOS and macOS, a precompiler macro
        // negates the radian value, if on iOS.
        #if os(iOS)
        self = CGAffineTransform(rotationAngle: -CGFloat(degree).degreeToRadian)
        #elseif os(macOS)
        self = CGAffineTransform(rotationAngle: CGFloat(degree).degreeToRadian)
        #endif
    }
}
