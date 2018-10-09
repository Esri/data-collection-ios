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
    
    /// Format a button's title with a header and an optional subheader offering
    /// the ability to specify a color for a series of control states.
    ///
    /// - Parameters:
    ///   - header: Two value tuple with a title string and title font.
    ///   - subheader: Two value tuple with a title string and title font (optional).
    ///   - controlStateColors: A dictionary of control states (keys) and their cooresponding colors (values).
    ///
    func setAttributed(header: (title: String, font: UIFont), subheader: (title: String, font: UIFont)? = nil, forControlStateColors controlStateColors: [UIControl.State: UIColor]) {
        
        // We want to build a NSAttributedString for every (control state: color) combo.
        for (state, color) in controlStateColors {
            
            // This is needed for building attributes of the NSAttributedString.
            var headerLength = header.title.count
            
            let headerRange = NSRange(location: 0, length: headerLength)
            
            // Format the header portion of the NSAttributedString.
            let attributedTitleString = NSMutableAttributedString(string: header.title)
            attributedTitleString.addAttributes([.foregroundColor : color, .font: header.font], range: headerRange)

            // Continue buliding the NSAttributedString if subheader has been provided.
            if let subheader = subheader {

                // Start with a new line.
                let newline = "\n"
                
                // Calculate the length of the subheader for building attributes of the NSAttributedString.
                headerLength += newline.count
                let subheaderLocation = headerLength
                let subheaderLength = subheader.title.count
                
                let subheaderAttributedString = NSAttributedString(string: "\(newline)\(subheader.title)")
                attributedTitleString.append(subheaderAttributedString)
                
                let subheaderRange = NSRange(location: subheaderLocation, length: subheaderLength)
                
                // Format the subheader portion of the NSAttributedString.
                attributedTitleString.addAttributes([.foregroundColor : color, .font: subheader.font], range: subheaderRange)
                
                titleLabel?.numberOfLines = 2
            }
            else {
                titleLabel?.numberOfLines = 1
            }
            
            self.setAttributedTitle(attributedTitleString, for: state)
        }
    }
}

