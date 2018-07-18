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

extension UIControlState: Hashable {

    public var hashValue: Int {
        return Int(rawValue)
    }
}

extension UIButton {
    
    func setTintColors(forControlStateColors controlStateColors: [UIControlState: UIColor]) {
        
        guard let normalImage = image(for: .normal) else {
            print("[Tint Color Error] no default image for control state normal.")
            return
        }
        
        for controlStateColor in controlStateColors {
            if let controlStateImage = normalImage.renderImage(toMaskWithColor: controlStateColor.value) {
                setImage(controlStateImage, for: controlStateColor.key)
            }
        }
    }
    
    func setAttributed(header: String, subheader: String? = nil, forControlStateColors controlStateColors: [UIControlState: UIColor], headerFont: UIFont, subheaderFont: UIFont? = nil) {
        
        var attributedTitleString: NSMutableAttributedString
        
        for controlStateColor in controlStateColors {
            
            let headerLocation = 0
            var headerLength = header.count
            
            let headerRange = NSRange(location: headerLocation, length: headerLength)

            if let subheader = subheader, let _ = subheaderFont {
                let newline = "\n"
                attributedTitleString = NSMutableAttributedString(string: "\(header)\(newline)\(subheader)")
                headerLength += newline.count
            }
            else {
                attributedTitleString = NSMutableAttributedString(string: header)
            }

            attributedTitleString.addAttributes([.foregroundColor : controlStateColor.value, .font: headerFont], range: headerRange)
            
            titleLabel?.numberOfLines = 1
            
            if let subheader = subheader, let subheaderFont = subheaderFont {
                
                let subheaderLocation = headerLength
                let subheaderLength = subheader.count
                
                let subheaderRange = NSRange(location: subheaderLocation, length: subheaderLength)
                
                titleLabel?.numberOfLines = 2
                
                attributedTitleString.addAttributes([.foregroundColor : controlStateColor.value, .font: subheaderFont], range: subheaderRange)
            }
            
            self.setAttributedTitle(attributedTitleString, for: controlStateColor.key)
        }
    }
}

