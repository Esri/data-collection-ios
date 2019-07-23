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

protocol ShrinkingViewDelegate {
    func shrinkingViewDidDragWith(yDelta: CGFloat)
    func shrinkingViewDidFinishDrag(thresholdReached: Bool)
}

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
    
    var delegate: ShrinkingViewDelegate?

    private struct DragThreshold {
        static let yOffset: CGFloat = 60
    }
    
    private var touchDownPoint: CGPoint?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // must be accepting user interaction
        guard isUserInteractionEnabled else {
            return
        }
        // animate
        scale = .shrink
        
        sendActions(for: .touchDown)
        
        if let touch = touches.first, let superview = self.superview {
            touchDownPoint = touch.location(in: superview)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        // must be accepting user interaction
        guard isUserInteractionEnabled,
            let touchDownPoint = touchDownPoint,
            let touch = touches.first,
            let superview = self.superview
            else {
            return
        }
        
        let currentLocation = touch.location(in: superview)
        
        delegate?.shrinkingViewDidDragWith(yDelta: touchDownPoint.y - currentLocation.y)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        // animate
        scale = .full
        
        sendActions(for: .touchCancel)
        
        touchDownPoint = nil
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        // must be accepting user interaction
        
        defer {
            // animate
            touchDownPoint = nil
            scale = .full
        }
        
        guard isUserInteractionEnabled,
            let touch = touches.first,
            let superview = self.superview
            else {
            return
        }
        
        let currentLocation = touch.location(in: superview)

        if let touchDownPoint = touchDownPoint {
            
            let delta = touchDownPoint.y - currentLocation.y
            
            if delta >= DragThreshold.yOffset || delta <= -DragThreshold.yOffset {
                delegate?.shrinkingViewDidFinishDrag(thresholdReached: true)
                return
            }
        }
        
        if frame.contains(currentLocation) {
            sendActions(for: .touchUpInside)
        }
        else {
            sendActions(for: .touchUpOutside)
        }
        
        delegate?.shrinkingViewDidFinishDrag(thresholdReached: false)
    }
}
