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
        
        do {
            try buildSublayers()
        }
        catch {
            print("[Error]", error.localizedDescription)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        generalInit()
        
        do {
            try buildSublayers()
        }
        catch {
            print("[Error:Assets]", (error as! AssetsError).localizedDescription)
        }
    }
    
    private func generalInit() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
    
    private func buildSublayers() throws {
        let scale = UIScreen.main.scale
        
        guard let treePinImage = UIImage(named: AssetName.pin)?.cgImage else {
            throw AssetsError.missingAsset(AssetName.pin)
        }
        
        guard let treeShadowImage = UIImage(named: AssetName.shadow)?.cgImage else {
            throw AssetsError.missingAsset(AssetName.shadow)
        }
        
        // establish origin
        let origin = CGPoint(x: 0.0, y: 0.0)
        
        // build tree shadow
        let treeShadowSize = CGSize(width: CGFloat(treeShadowImage.width)/scale, height: CGFloat(treeShadowImage.height)/scale)
        shadowLayer.frame = CGRect(origin: origin, size: treeShadowSize)
        shadowLayer.contents = treeShadowImage
        layer.addSublayer(shadowLayer)
        
        // build tree pin
        let treePinSize = CGSize(width: CGFloat(treePinImage.width)/scale, height: CGFloat(treePinImage.height)/scale)
        pinLayer.frame = CGRect(origin: origin, size: treePinSize)
        pinLayer.contents = treePinImage
        layer.addSublayer(pinLayer)
    }
    
    override func layoutSubviews() {
        
        /*  ._______  _  _
         *  |       |  |  |
         *  |       |  |  |-Height of pin
         *  !_______|  |  | _
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
