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


final class PopupStringCell: PopupTextViewCell {

    override var viewHeight: CGFloat {
        
        guard let field = field else {
            return super.viewHeight
        }

        let lineHeight = CGFloat(30.0)
        
        switch field.stringFieldOption {
        case .singleLine, .unknown:
            return lineHeight
        case .multiLine, .richText:
            return lineHeight * 3.0
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        
        guard let field = field, field.stringFieldOption == .richText else {
            updateValue(textView.text)
            return
        }
        
        updateValue(textView.attributedText)
    }
}
