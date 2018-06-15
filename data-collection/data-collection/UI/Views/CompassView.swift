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
import ArcGIS

@IBDesignable class CompassView: UIButton {
    
    var compassFadeTriggerTimer: Timer?
    private var mapViewRotationObserver: NSKeyValueObservation?
    
    struct Alpha {
        static let present: CGFloat = 1.0
        static let hidden: CGFloat = 0.0
    }
    
    weak var mapView: AGSMapView? {
        didSet {
            mapViewRotationObserver?.invalidate()
            mapViewRotationObserver = nil
            
            guard let mapView = mapView else {
                return
            }
            
            alpha = mapView.isNorthFacingUp ? Alpha.hidden : Alpha.present
            
            mapViewRotationObserver = mapView.observe(\.rotation, options:[.new, .old]) { [weak self] (mapView, change) in
                
                DispatchQueue.main.async { [weak self] in
                    
                    self?.alpha = Alpha.present
                    
                    guard let rotationValue = change.newValue else {
                        return
                    }
                    
                    self?.transform(forRotation: rotationValue)
                    self?.adjustForNorth()
                }
            }
        }
    }
    
    deinit {
        mapViewRotationObserver?.invalidate()
        mapViewRotationObserver = nil
        mapView = nil
    }
    
    @IBInspectable var compassImage: UIImage = UIImage(named: "Compass")! {
        didSet {
            setBackgroundImage(compassImage, for: .normal)
        }
    }
    
    private func transform(forRotation rotation: Double) {
        compassFadeTriggerTimer?.invalidate()
        compassFadeTriggerTimer = nil
        transform = CGAffineTransform(rotationAngle: CGFloat(-rotation.asRadians))
    }
    
    private func adjustForNorth() {
        
        guard let mapView = mapView else {
            return
        }
        if mapView.isNorthFacingUp {
            compassFadeTriggerTimer?.invalidate()
            compassFadeTriggerTimer = nil
            compassFadeTriggerTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { [weak self] (_) in
                UIView.animate(withDuration: 0.6, delay: 0.0, options: .curveEaseOut, animations: { self?.alpha = Alpha.hidden }, completion: nil)
            })
        }
    }

    @objc func didTapCompass(sender: UIButton) {
        guard let mapView = mapView else {
            return
        }
        mapView.setViewpointRotation(0.0, completion: nil)
    }
    
    private func addButtonTouchEvent() {
        addTarget(self, action: #selector(CompassView.didTapCompass(sender:)), for: .touchUpInside)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addButtonTouchEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addButtonTouchEvent()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setBackgroundImage(compassImage, for: .normal)
        setNeedsLayout()
        setNeedsDisplay()
    }
}
