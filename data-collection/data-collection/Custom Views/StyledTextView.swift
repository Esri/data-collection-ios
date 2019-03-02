//// Copyright 2019 Esri
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

class StyledTextView: UITextView {
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            guard isUserInteractionEnabled != oldValue else { return }
            stylize()
        }
    }
    
    private func stylize() {
        
        if isUserInteractionEnabled {
            
            // Text container text inset and padding
            textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            textContainer.lineFragmentPadding = 8
            
            // Border
            layer.borderColor = UIColor(white: 0.8, alpha: 1.0).cgColor
            layer.borderWidth = 1.0 / UIScreen.main.scale
            layer.cornerRadius = 5
            clipsToBounds = true
        }
        else {
            
            // Text container inset and padding
            textContainerInset = .zero
            textContainer.lineFragmentPadding = 0
            
            // Border
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0.0
            layer.cornerRadius = 0
            clipsToBounds = true
        }
    }
}
