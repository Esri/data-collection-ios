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

extension CGPoint {
    
    /// Builds a new `CGPoint` by modifying x.
    ///
    /// - Parameter xDelta: By how much to modify x.
    ///
    /// - Returns: A new point with a new, modified x value.
    
    func modified(x xDelta: CGFloat) -> CGPoint {
        return CGPoint(x: x + xDelta, y: y)
    }
    
    /// Builds a new `CGPoint` by modifying y.
    ///
    /// - Parameter yDelta: By how much to modify y.
    ///
    /// - Returns: A new point with a new, modified y value.
    
    func modified(y yDelta: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: y + yDelta)
    }
    
    /// Modifies a point's x value in place.
    ///
    /// - Parameter xDelta: By how much to modify x.
    
    mutating func modify(x xDelta: CGFloat) {
        self = modified(x: xDelta)
    }
    
    /// Modifies a point's y value in place.
    ///
    /// - Parameter yDelta: By how much to modify y.
    
    mutating func modify(y yDelta: CGFloat) {
        self = modified(y: yDelta)
    }
}
