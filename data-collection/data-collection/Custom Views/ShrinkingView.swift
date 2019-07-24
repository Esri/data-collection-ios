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
    
    // MARK:- Shrinking
    
    private enum ShrinkScale: CGFloat {
        
        case shrink = 0.98
        case full = 1.0
        
        fileprivate var transformation: CGAffineTransform {
            return CGAffineTransform(scaleX: self.rawValue, y: self.rawValue)
        }
    }
    
    private var scale: ShrinkScale = .full {
        didSet {
            UIView.animate(withDuration: 0.06) { [weak self] in
                if let transformation = self?.scale.transformation {
                    self?.transform = transformation
                }
            }
        }
    }
    
    // MARK:- Drag Y Offset
        
    private var touchDownPoint: CGPoint?
    
    private var currentTouchPoint: CGPoint?
    
    var yDelta: CGFloat {
        if let down = touchDownPoint, let current = currentTouchPoint {
            return down.y - current.y
        }
        else {
            return 0
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        touchDownPoint = nil
        currentTouchPoint = nil
        
        guard isUserInteractionEnabled else { return }
                
        if let touch = touches.first, let superview = self.superview {
            touchDownPoint = touch.location(in: superview)
            currentTouchPoint = touchDownPoint
        }
        
        scale = .shrink

        sendActions(for: .touchDown)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard isUserInteractionEnabled, let touch = touches.first, let superview = self.superview else {
            return
        }
        
        currentTouchPoint = touch.location(in: superview)
        
        sendActions(for: .touchDragInside)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        scale = .full
        
        touchDownPoint = nil
        currentTouchPoint = nil
        
        sendActions(for: .touchCancel)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        defer {
            touchDownPoint = nil
            currentTouchPoint = nil
            scale = .full
        }
        
        guard isUserInteractionEnabled, let touch = touches.first, let superview = self.superview else { return }
        
        let current = touch.location(in: superview)
        
        currentTouchPoint = current
        
        if yDelta <= -.dragThresholdYDelta {
            sendActions(for: .touchDragExit)
        }
        else if yDelta >= .dragThresholdYDelta {
            sendActions(for: .touchCancel)
        }
        else if frame.contains(current) {
            sendActions(for: .touchUpInside)
        }
        else {
            sendActions(for: .touchUpOutside)
        }
    }
}

private extension CGFloat {
    static let dragThresholdYDelta: CGFloat = 12
}
