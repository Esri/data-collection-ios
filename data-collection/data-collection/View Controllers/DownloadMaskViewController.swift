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

import Foundation
import UIKit

class DownloadMaskViewController: AppContextAwareController {
    
    let borderWidth: CGFloat = 2.0
    
    @IBOutlet weak var maskView: UIView!
    var borderView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        borderView = UIView()
        borderView?.backgroundColor = .clear
        borderView?.layer.borderColor = AppConfiguration.appColors.primary.cgColor
        borderView?.layer.borderWidth = borderWidth
        
        adjustFrameInset()

        if let borderView = borderView {
            view.addSubview(borderView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let path = UIBezierPath(rect: maskView.frame)
        let maskLayer = CAShapeLayer()
        path.append(UIBezierPath(rect: view.bounds))
        maskLayer.fillRule = kCAFillRuleEvenOdd
        maskLayer.path = path.cgPath
        self.view.layer.mask = maskLayer
        
        adjustFrameInset()
    }
    
    func adjustFrameInset() {
        borderView?.frame = maskView.frame.insetBy(dx: -borderWidth, dy: -borderWidth)
    }
}
