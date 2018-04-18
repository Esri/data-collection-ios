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

@IBDesignable class ActivityBarView: UIView {
    
    @IBInspectable var colorA: UIColor = .darkGray {
        didSet {
            updateAnimationsForNewColor()
        }
    }
    
    @IBInspectable var colorB: UIColor = .lightGray {
        didSet {
            updateAnimationsForNewColor()
        }
    }
    
    private var mapViewLoadStatusObserver: NSKeyValueObservation?
    
    weak var mapView: AGSMapView? {
        didSet {
            stopProgressAnimation()
            
            mapViewLoadStatusObserver?.invalidate()
            mapViewLoadStatusObserver = nil
            
            guard let mapView = mapView else {
                return
            }
            
            mapViewLoadStatusObserver = mapView.observe(\.drawStatus, options:[.new, .old]) { [weak self] (mapView, _) in
                print("[Draw Status] \(mapView.drawStatus)")
                if mapView.drawStatus == .inProgress {
                    self?.startProgressAnimation()
                }
                else {
                    self?.stopProgressAnimation()
                }
            }
        }
    }
    
    private func updateAnimationsForNewColor() {
        layer.removeAllAnimations()
        if isAnimating {
            startProgressAnimation()
        }
    }
    
    private var isAnimating: Bool = false
    
    convenience init(sized: CGSize, colorA: UIColor, colorB: UIColor) {
        let frame = CGRect(origin: CGPoint(x: 0, y: -sized.height), size: sized)
        self.init(frame: frame)
        self.colorA = colorA
        self.colorB = colorB
        resetBackgroundColor()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        resetBackgroundColor()
    }
    
    public func resetBackgroundColor() {
        isAnimating = false
        backgroundColor = colorA
    }
    
    public func startProgressAnimation() {
        isAnimating = true
        alpha = 1.0
        isHidden = false
        UIView.animate(withDuration: 0.1, animations: { [unowned activity = self] in
            activity.frame = activity.rect(forVisible: true)
        }, completion: { [unowned activity = self] (completion) in
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.autoreverse, .`repeat`], animations: {
                activity.backgroundColor = activity.backgroundColor == activity.colorA ? activity.colorB : activity.colorA
            })
        })
    }
    
    public func stopProgressAnimation() {
        layer.removeAllAnimations()
        resetBackgroundColor()
        UIView.animate(withDuration: 0.1, animations: { [unowned activity = self] in
            activity.layer.frame = activity.rect(forVisible: false)
        }, completion: { [unowned activity = self] (completion) in
            activity.alpha = 0.0
            activity.isHidden = true
            activity.layer.removeAllAnimations()
        })
    }
    
    private func rect(forVisible visible: Bool) -> CGRect {
        let y = visible ? 0.0 : -frame.size.height
        return CGRect(x: 0.0, y: y, width: frame.size.width, height: frame.size.height)
    }
}
