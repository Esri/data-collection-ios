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

class PopupAttributeTextFieldCell: UITableViewCell {
    
    private var title: String = ""
    
    @IBOutlet weak var attributeTitleLabel: UILabel!
    
    private var value: AttributeValue = ("", nil)
    
    @IBOutlet weak var attributeValueTextField: StyledTextField! {
        didSet {
            attributeValueTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            attributeValueTextField.delegate = self
        }
    }
    
    weak var delegate: PopupAttributeCellDelegate?
    
    var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        attributeValueTextField.isUserInteractionEnabled = editing
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.popupAttributeCell(self, valueDidChange: textField.text, at: indexPath)
    }
}

extension PopupAttributeTextFieldCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.popupAttributeCell(self, didBecomeFirstResponder: attributeValueTextField)
    }
}

extension PopupAttributeTextFieldCell: PopupAttributeCell {
    
    func setTitle(_ title: String, value: AttributeValue) {
        
        // Title
        self.title = title
        attributeTitleLabel.text = self.title
        
        // Value
        self.value = value
        attributeValueTextField.text = value.formatted
        
        attributeTitleLabel.considerEmptyString()
    }
    
    var firstResponder: UIView? {
        return attributeValueTextField
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
    
    
}
