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

class PopupAttributeTextViewCell: UITableViewCell {
    
    private var title: String = ""

    @IBOutlet weak var attributeTitleLabel: UILabel!
    
    private var value: AttributeValue = ("", nil)

    @IBOutlet weak var attributeValueTextView: StyledTextView! {
        didSet {
            attributeValueTextView.delegate = self
            attributeValueTextView.setEditing(isEditing)
        }
    }
    
    weak var delegate: PopupAttributeCellDelegate?
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        attributeValueTextView.isSelectable = editing
        attributeValueTextView.isEditable = editing
        attributeValueTextView.isScrollEnabled = editing
        
        attributeValueTextView.setEditing(editing)
    }
}

extension PopupAttributeTextViewCell: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.popupAttributeCell(self, didBecomeFirstResponder: attributeValueTextView)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        delegate?.popupAttributeCell(self, valueDidChange: textView.text)
    }
}

extension PopupAttributeTextViewCell: PopupAttributeCell {
    
    func setTitle(_ title: String, value: AttributeValue) {
        
        // Title
        self.title = title
        attributeTitleLabel.text = self.title
        
        // Value
        self.value = value
        attributeValueTextView.text = value.formatted
        
        attributeTitleLabel.considerEmptyString()
    }
    
    func setValidity(_ error: Error?) {
        
        if let error = error {
            attributeTitleLabel.text = String(format: "%@: %@", self.title, error.localizedDescription)
            attributeTitleLabel.textColor = .destructive
        }
        else {
            attributeTitleLabel.text = self.title
            attributeTitleLabel.textColor = .lightGray
        }
    }
    
    var firstResponder: UIView? {
        return attributeValueTextView
    }
    
    
}
