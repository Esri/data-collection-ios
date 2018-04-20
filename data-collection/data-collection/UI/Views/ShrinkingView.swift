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

class ShrinkingView: UIView {
    
    public var shrinkScale: CGFloat = 0.98
    private var fullScale: CGFloat = 1.0
    
    var actionClosure: (() -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // must be accepting user interaction
        guard isUserInteractionEnabled else {
            return
        }
        // animate
        UIView.animate(withDuration: 0.06) {
            self.transform = CGAffineTransform(scaleX: self.shrinkScale, y: self.shrinkScale)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        // animate
        UIView.animate(withDuration: 0.06) {
            self.transform = CGAffineTransform(scaleX: self.fullScale, y: self.fullScale)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        // must be accepting user interaction
        guard isUserInteractionEnabled else {
            return
        }
        // animate
        UIView.animate(withDuration: 0.06) {
            self.transform = CGAffineTransform(scaleX: self.fullScale, y: self.fullScale)
        }
        
        if let touch = touches.first, bounds.contains(touch.location(in: self)) {
            if let action = actionClosure, self.isUserInteractionEnabled == true {
                action()
            }
        }
    }
}
