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

class ActivityBarView: UIView {
    
    init(mapView: AGSMapView, colors:(a: UIColor, b: UIColor)) {
        self.mapView = mapView
        self.colorA = colors.a
        self.colorB = colors.b
        
        super.init(frame: .zero)
        
        mapViewLoadStatusObserver = mapView.observe(\.drawStatus, options:[]) { [weak self] (mapView, _) in
            DispatchQueue.main.async { [weak self] in
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var mapView: AGSMapView?
    
    var colorA: UIColor {
        didSet {
            updateAnimationsForNewColor()
        }
    }
    
    var colorB: UIColor {
        didSet {
            updateAnimationsForNewColor()
        }
    }
    
    private var mapViewLoadStatusObserver: NSKeyValueObservation?
    
    private var isAnimating: Bool = false

    private func updateAnimationsForNewColor() {
        layer.removeAllAnimations()
        if isAnimating {
            startProgressAnimation()
        }
    }
    
    public func resetBackgroundColor() {
        isAnimating = false
        backgroundColor = colorA
    }
    
    private func startProgressAnimation() {
        isAnimating = true
        alpha = 1.0
        isHidden = false
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.alpha = 1.0
        }, completion: { [weak self] (completion) in
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.autoreverse, .repeat], animations: {
                self?.swapBackgroundColor()
            })
        })
    }
    
    private func stopProgressAnimation() {
        isAnimating = false
        layer.removeAllAnimations()
        resetBackgroundColor()
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.alpha = 0.0
        }, completion: {  [weak self] (completion) in
            self?.removeAnimations()
        })
    }
    
    private func removeAnimations() {
        alpha = 0.0
        isHidden = true
        layer.removeAllAnimations()
    }
    
    private func swapBackgroundColor() {
        backgroundColor = backgroundColor == colorA ? colorB : colorA
    }
}
