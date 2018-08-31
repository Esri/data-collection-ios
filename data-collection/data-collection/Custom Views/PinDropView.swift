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

class PinDropView: UIView {
    
    struct AssetName {
        static let pin = "GenericPin"
        static let shadow = "PinShadow"
    }
    
    private let pinLayer = CALayer()
    private let shadowLayer = CALayer()
    
    var animationDuration: CFTimeInterval = 0.1
    
    var shouldAnimate: Bool = true
    
    var pinDropped: Bool = true {
        willSet {
            shouldAnimate = newValue != pinDropped
        }
        didSet {
            if pinDropped {
                if shouldAnimate { dropPin() }
            }
            else {
                if shouldAnimate { removePin() }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        generalInit()
        buildSublayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        generalInit()
        buildSublayers()
    }
    
    private func generalInit() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
    
    private func buildSublayers() {
        let scale = UIScreen.main.scale
        
        guard let pinImage = UIImage(named: AssetName.pin)?.cgImage else {
            return assertionFailure("App bundle must contain asset named \(AssetName.pin).")
        }
        
        guard let pinShadowImage = UIImage(named: AssetName.shadow)?.cgImage else {
            return assertionFailure("App bundle must contain asset named \(AssetName.shadow).")
        }
        
        // build pin shadow
        let pinShadowSize = CGSize(width: CGFloat(pinShadowImage.width)/scale, height: CGFloat(pinShadowImage.height)/scale)
        shadowLayer.frame = CGRect(origin: .zero, size: pinShadowSize)
        shadowLayer.contents = pinShadowImage
        layer.addSublayer(shadowLayer)
        
        // build pin
        let pinSize = CGSize(width: CGFloat(pinImage.width)/scale, height: CGFloat(pinImage.height)/scale)
        pinLayer.frame = CGRect(origin: .zero, size: pinSize)
        pinLayer.contents = pinImage
        layer.addSublayer(pinLayer)
    }
    
    override func layoutSubviews() {
        
        /*  ._______  _  _
         *  |       |  |  |
         *  |   O   |  |  |-Height of pin
         *  !___|___|  |  | _
         *  |___.___|  | _|  |
         *  |_______|  |    _|-Height of shadow
         *  |       |  |
         *  |       |  |-Ideal height
         *   -------  -
         */
        
        // ideal height of pin and shadow
        let idealHeight = pinLayer.frame.size.height*2.0
        // pin origin
        let pinX = (frame.size.width/2.0) - (pinLayer.frame.size.width/2.0)
        let pinY = (frame.size.height/2.0) - (idealHeight/2.0)
        // shadow origin
        let shadowX = (frame.size.width/2.0) - (shadowLayer.frame.size.width/2.0)
        let shadowY = pinY+(idealHeight/2.0) - (shadowLayer.frame.size.height/2.0)
        
        pinLayer.frame.modify(origin: CGPoint(x: pinX, y: pinY))
        shadowLayer.frame.modify(origin: CGPoint(x: shadowX, y: shadowY))

    }
    
    func dropPin(animated: Bool = true) {
        
        // finishing values
        pinLayer.opacity = 1
        shadowLayer.opacity = 1
        
        // animation
        if animated {
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn))
            
            let pinDrop = CABasicAnimation(keyPath: "position")
            pinDrop.fromValue = pinLayer.position.modified(y: -30.0)
            
            let pinOpacity = CABasicAnimation(keyPath: "opacity")
            pinOpacity.fromValue = 0
            
            let shadowOpacity = CABasicAnimation(keyPath: "opacity")
            shadowOpacity.fromValue = 0
            
            pinLayer.removeAllAnimations()
            shadowLayer.removeAllAnimations()
            
            pinLayer.add(pinDrop, forKey: "pinDropView.pinLayer.position")
            pinLayer.add(pinOpacity, forKey: "pinDropView.pinLayer.opacity")
            shadowLayer.add(shadowOpacity, forKey: "pinDropView.shadowLayer.opacity")
            
            CATransaction.commit()
        }
    }
    
    func removePin(animated: Bool = true) {
        
        // finishing values
        pinLayer.opacity = 0
        shadowLayer.opacity = 0
        
        // animation
        if animated {
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn))
            
            let pinOpacity = CABasicAnimation(keyPath: "opacity")
            pinOpacity.fromValue = 1
            
            let shadowOpacity = CABasicAnimation(keyPath: "opacity")
            shadowOpacity.fromValue = 1
            
            pinLayer.removeAllAnimations()
            shadowLayer.removeAllAnimations()
            
            pinLayer.add(pinOpacity, forKey: "pinDropView.pinLayer.opacity")
            shadowLayer.add(shadowOpacity, forKey: "pinDropView.shadowLayer.opacity")
            
            CATransaction.commit()
        }
    }
}
