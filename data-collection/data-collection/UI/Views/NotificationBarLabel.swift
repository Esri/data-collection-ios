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

import UIKit

class NotificationBarLabel: UILabel {
    
    private var hideLabelTimer: Timer?
    
    private static let slideAnimationDuration: TimeInterval = 0.4
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func showLabel(withNotificationMessage message: String, forDuration duration: TimeInterval) {
        
        text = message
        hideLabelTimer?.invalidate()
        hideLabelTimer = nil
        alpha = 1.0
        isHidden = false
        frame = rect(forVisible: false)
        
        UIView.animate(withDuration: NotificationBarLabel.slideAnimationDuration, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
            self?.setRect(forVisible: true)
        }, completion: { [weak self] (completion) in
            self?.hideLabelTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { [weak self] (_) in
                self?.hideLabel()
            })
        })
    }
    
    public func hideLabel() {

        UIView.animate(withDuration: NotificationBarLabel.slideAnimationDuration, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
            self?.setRect(forVisible: false)
        }, completion: {(completion) in
            self.alpha = 0.0
            self.isHidden = true
        })
    }
    
    private func setRect(forVisible visible: Bool) {
        frame = rect(forVisible: visible)
    }
    
    private func rect(forVisible visible: Bool) -> CGRect {
        let y = visible ? 0.0 : -frame.size.height
        return CGRect(x: 0.0, y: y, width: frame.size.width, height: frame.size.height)
    }
    
}
