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

extension UIButton {
    
    func setAttributed(header: String, subheader: String? = nil, forControlStateColors controlStateColors: [UIControlState: UIColor], headerFont: UIFont, subheaderFont: UIFont? = nil) {
        
        var attributedTitleString: NSMutableAttributedString
        
        let headerLocation = 0

        for (state, color) in controlStateColors {
            
            var headerLength = header.count
            
            let headerRange = NSRange(location: headerLocation, length: headerLength)
            
            attributedTitleString = NSMutableAttributedString(string: header)
            attributedTitleString.addAttributes([.foregroundColor : color, .font: headerFont], range: headerRange)

            if let subheader = subheader, let subheaderFont = subheaderFont {

                let newline = "\n"
                
                headerLength += newline.count
                
                let subheaderLocation = headerLength
                let subheaderLength = subheader.count
                
                let subheaderAttributedString = NSAttributedString(string: "\(newline)\(subheader)")
                attributedTitleString.append(subheaderAttributedString)
                
                let subheaderRange = NSRange(location: subheaderLocation, length: subheaderLength)
                
                attributedTitleString.addAttributes([.foregroundColor : color, .font: subheaderFont], range: subheaderRange)
                
                titleLabel?.numberOfLines = 2
            }
            else {
                titleLabel?.numberOfLines = 1
            }
            
            self.setAttributedTitle(attributedTitleString, for: state)
        }
    }
}

