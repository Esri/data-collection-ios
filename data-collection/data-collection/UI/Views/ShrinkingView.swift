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

class ShrinkingView: UIControl {
    
    enum ShrinkScale: CGFloat {
        
        case shrink = 0.98
        case full = 1.0
        
        fileprivate var transformation: CGAffineTransform {
            return CGAffineTransform(scaleX: self.rawValue, y: self.rawValue)
        }
    }
    
    var scale: ShrinkScale = .full {
        didSet {
            UIView.animate(withDuration: 0.06) { [weak self] in
                if let transformation = self?.scale.transformation {
                    self?.transform = transformation
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // must be accepting user interaction
        guard isUserInteractionEnabled else {
            return
        }
        // animate
        scale = .shrink
        
        sendActions(for: .touchDown)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        // animate
        scale = .full
        
        sendActions(for: .touchCancel)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        // must be accepting user interaction
        guard isUserInteractionEnabled else {
            return
        }
        // animate
        scale = .full
        
        if let touch = touches.first, bounds.contains(touch.location(in: self)) {
            sendActions(for: .touchUpInside)
        }
        else {
            sendActions(for: .touchUpOutside)
        }
    }
}
