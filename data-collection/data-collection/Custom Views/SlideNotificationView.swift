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
class SlideNotificationView: UIView {
    
    @IBInspectable var messageBackgroundColor: UIColor! = .darkGray {
        didSet {
            label.backgroundColor = messageBackgroundColor
        }
    }
    
    @IBInspectable var messageTextColor: UIColor! = .white {
        didSet {
            label.textColor = messageTextColor
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
        
        // The view is intended to be a non-interactive container for a label that slides on and off the screen.
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
        
        // Build label that adjusts for content size category.
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.allowsDefaultTighteningForTruncation = true
        label.adjustsFontForContentSizeCategory = true
        label.backgroundColor = messageBackgroundColor
        label.textColor = messageTextColor
        label.numberOfLines = 1
        
        // Add label.
        addSubview(label)
        
        // This allows the label to dictate the height of the view, when dynamic type is changed.
        setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // Attach the label's anchors to the view's anchors.
        let leading = label.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = label.trailingAnchor.constraint(equalTo: trailingAnchor)
        
        // Maintain a reference to the top anchor constraint with the priority set to `.required` (the default value).
        // Disabling this constraint will fallback to the bottom constraint (see a few lines below).
        let top = label.topAnchor.constraint(equalTo: topAnchor)
        top.priority = .required
        topSlideConstraint = top

        // Add a bottom anchor constraint that is equal to the superview's *top anchor* with a lower priority.
        // This anchor will become active when `topSlideConstraint` is disabled.
        let bottom = label.bottomAnchor.constraint(equalTo: topAnchor)
        bottom.priority = .defaultHigh
        
        // Set a height constraint.
        let height = NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0.0)
        
        // Activate.
        NSLayoutConstraint.activate([top, leading, trailing, bottom, height])
        
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
            self?.hideLabelTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { (_) in self?.hideLabel() })
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
        topSlideConstraint.isActive = true
        layoutIfNeeded()
    }
    
    private func hideNotificationLabel() {
        topSlideConstraint.isActive = false
        layoutIfNeeded()
    }
    
    private func clearTimer() {
        hideLabelTimer?.invalidate()
        hideLabelTimer = nil
    }
}
