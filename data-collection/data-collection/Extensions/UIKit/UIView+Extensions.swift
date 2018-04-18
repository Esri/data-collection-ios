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

import UIKit

// MARK: UIView Animation

// UIView Animation Callback
typealias UIViewAnimations = () -> Void

// MARK: Gestures

extension UIView {
    func removeGestures() {
        if let gestures = gestureRecognizers {
            for gesture in gestures {
                removeGestureRecognizer(gesture)
            }
        }
    }
}

// Core Graphcs
extension UIView {
    var boundsCenter: CGPoint {
        return CGPoint(x: bounds.size.width/2.0, y: bounds.size.height/2.0)
    }
}

// MARK: Style

extension UIView {
//    func stylizeBorder() {
//        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
//        layer.borderWidth = 1
//        layer.cornerRadius = 5
//        clipsToBounds = true
//    }
}

