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
import CoreGraphics

extension CGRect {
    
    /// Facilitates building a center point for a rect.
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

extension CGRect {
    
    /// Builds a new `CGRect` by modifying x.
    ///
    /// - Parameter xDelta: By how much to modify x.
    ///
    /// - Returns: A new rect with a new, modified x value.
    
    func modified(x xDelta: CGFloat) -> CGRect {
        return modified(origin: origin.modified(x: xDelta))
    }
    
    /// Builds a new `CGRect` by modifying y.
    ///
    /// - Parameter yDelta: By how much to modify y.
    ///
    /// - Returns: A new rect with a new, modified y value.
    
    func modified(y yDelta: CGFloat) -> CGRect {
        return modified(origin: origin.modified(y: yDelta))
    }
    
    /// Builds a new `CGRect` by modifying origin.
    ///
    /// - Parameter originDelta: By how much to modify origin.
    ///
    /// - Returns: A new rect with a new, modified origin value.
    
    func modified(origin originDelta: CGPoint) -> CGRect {
        return CGRect(origin: originDelta, size: size)
    }
    
    /// Modifies a rect's x value in place.
    ///
    /// - Parameter xDelta: By how much to modify x.
    
    mutating func modify(x: CGFloat) {
        self = modified(x: x)
    }

    /// Modifies a rect's y value in place.
    ///
    /// - Parameter yDelta: By how much to modify y.
    
    mutating func modify(y: CGFloat) {
        self = modified(y: y)
    }
    
    /// Modifies a rect's origin value in place.
    ///
    /// - Parameter originDelta: By how much to modify origin.
    
    mutating func modify(origin: CGPoint) {
        self = modified(origin: origin)
    }
}
