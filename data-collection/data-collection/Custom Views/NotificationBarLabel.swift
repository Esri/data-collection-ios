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

@IBDesignable
class NotificationBarLabel: UIView {
    
    @IBInspectable var labelBackgroundColor: UIColor! = .darkGray {
        didSet {
            label.backgroundColor = labelBackgroundColor
        }
    }
    
    @IBInspectable var labelFontColor: UIColor! = .white {
        didSet {
            label.textColor = labelFontColor
        }
    }
    
    @IBInspectable var slideAnimationDuration: Double = 0.4
    
    private var hideLabelTimer: Timer?
    
    private let label = UILabel()
    
    private var topSlideConstraint: NSLayoutConstraint!
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
        
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = labelBackgroundColor ?? .darkGray
        label.textColor = labelFontColor ?? .white
        label.numberOfLines = 1
        
        addSubview(label)
        
        let top = label.topAnchor.constraint(equalTo: topAnchor, constant: 0.0)
        let leading = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0)
        let trailing = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0.0)
        
        let height = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        
        topSlideConstraint = top
        
        NSLayoutConstraint.activate([top, leading, trailing, height])
        
        hideNotificationLabel()
    }

    public func showLabel(withNotificationMessage message: String, forDuration duration: TimeInterval) {
        
        clearTimer()
        
        label.text = message
        
        hideNotificationLabel()
        
        let animations: UIViewAnimations = { [weak self] in
            self?.showNotificationLabel()
        }
        
        let completion: UIViewAnimationCompletion = { [weak self] (_) in
            
            let block: TimerBlock = { (_) in self?.hideLabel() }
            
            self?.hideLabelTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: block)
        }
        
        UIView.animate(withDuration: slideAnimationDuration, delay: 0.0, options: .curveEaseOut, animations: animations, completion: completion)
    }
    
    private func hideLabel() {

        let animations: UIViewAnimations = { [weak self] in
            self?.hideNotificationLabel()
        }
        
        let completion: UIViewAnimationCompletion = { [weak self] (_) in
            self?.clearTimer()
        }
        
        UIView.animate(withDuration: slideAnimationDuration, delay: 0.0, options: .curveEaseOut, animations: animations, completion: completion)
    }
    
    private func showNotificationLabel() {
        topSlideConstraint.constant = 0
        layoutIfNeeded()
    }
    
    private func hideNotificationLabel() {
        topSlideConstraint.constant = -bounds.size.height
        layoutIfNeeded()
    }
    
    private func clearTimer() {
        hideLabelTimer?.invalidate()
        hideLabelTimer = nil
    }
}
