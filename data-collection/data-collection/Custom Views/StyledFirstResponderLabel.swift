//// Copyright 2019 Esri
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

protocol StyledFirstResponderLabelDelegate: AnyObject {
    func inputViewForStyledFirstResponderLabel(_ label: StyledFirstResponderLabel) -> UIView?
}

@IBDesignable
class StyledFirstResponderLabel: UILabel {
    
    private let defaultBorderColor: UIColor = UIColor(white: 0.8, alpha: 1.0)
    
    private var derivedBorderColor: UIColor?
    
    @IBInspectable override dynamic var tintColor: UIColor! {
        set {
            derivedBorderColor = newValue
        }
        get {
            return derivedBorderColor ?? defaultBorderColor
        }
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        styleForIsUserInteractionEnabled()
    }
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            guard isUserInteractionEnabled != oldValue else { return }
            styleForIsUserInteractionEnabled()
        }
    }
    
    private let horizontalInset: CGFloat = 7.0
    private let verticalInset: CGFloat = 5.0
    
    private lazy var insets: UIEdgeInsets = {
        return UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }()

    override func drawText(in rect: CGRect) {
        
        if isUserInteractionEnabled {
            super.drawText(in: rect.inset(by: insets))
        }
        else {
            super.drawText(in: rect)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        
        if isUserInteractionEnabled {
            let size = super.intrinsicContentSize
            return CGSize(width: size.width + horizontalInset * 2,
                          height: size.height + verticalInset * 2)
        }
        else {
            return super.intrinsicContentSize
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    weak var delegate: StyledFirstResponderLabelDelegate?
    
    private func initialize() {
        
        // 1. Enable user interaction.
        isUserInteractionEnabled = true
        
        // 2. Add gesture recognizer.
        let tap = UITapGestureRecognizer(target: self, action: #selector(userDidTapLabel(_:)))
        self.addGestureRecognizer(tap)
        
        styleForIsUserInteractionEnabled()
    }
    
    private func styleForIsUserInteractionEnabled() {
        
        if isUserInteractionEnabled {
            
            if isFirstResponder {
                layer.borderColor = tintColor.cgColor
            }
            else {
                layer.borderColor = defaultBorderColor.cgColor
            }
            
            layer.borderWidth = 1.0 / UIScreen.main.scale
            layer.cornerRadius = 5
            clipsToBounds = true
        }
        else {
            
            layer.borderColor = nil
            layer.borderWidth = 0
            layer.cornerRadius = 0
            clipsToBounds = false
        }
    }
    
    @objc func userDidTapLabel(_ sender: Any) {
        if canBecomeFirstResponder {
            becomeFirstResponder()
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        styleForIsUserInteractionEnabled()
        return result
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        styleForIsUserInteractionEnabled()
        return result
    }
    
    override var inputView: UIView? {
        return delegate?.inputViewForStyledFirstResponderLabel(self)
    }
    
    private var _inputAccessoryView: UIView?
}

extension StyledFirstResponderLabel: UIResponderInputAccessoryViewProtocol {
    
    override var inputAccessoryView: UIView? {
        get {
            return _inputAccessoryView
        }
        set {
            _inputAccessoryView = newValue
        }
    }
}
