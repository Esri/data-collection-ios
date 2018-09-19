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
    
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

extension CGRect {
    
    func modified(x xDelta: CGFloat) -> CGRect {
        return modified(origin: origin.modified(x: xDelta))
    }
    
    func modified(y yDelta: CGFloat) -> CGRect {
        return modified(origin: origin.modified(y: yDelta))
    }
    
    func modified(origin originDelta: CGPoint) -> CGRect {
        return CGRect(origin: originDelta, size: size)
    }
    
    mutating func modify(x: CGFloat) {
        self = modified(x: x)
    }
    
    mutating func modify(y: CGFloat) {
        self = modified(y: y)
    }
    
    mutating func modify(origin: CGPoint) {
        self = modified(origin: origin)
    }
}