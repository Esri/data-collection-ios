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

class PopupAttributeDateCell: UITableViewCell {
    
    @IBOutlet weak var attributeTitleLabel: UILabel!
    
    @IBOutlet weak var attributeValueLabel: StyledFirstResponderLabel! {
        didSet {
            attributeValueLabel.delegate = self
        }
    }
    
    private var title: String = ""
    
    private var value: AttributeValue = ("", nil)
    
    weak var delegate: PopupAttributeCellDelegate?
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        attributeValueLabel.isUserInteractionEnabled = editing
    }
}

extension PopupAttributeDateCell: PopupAttributeCell {
    
    func setTitle(_ title: String, value: AttributeValue) {
        
        // Title
        self.title = title
        attributeTitleLabel.text = self.title
        
        // Value
        self.value = value
        attributeValueLabel.text = self.value.formatted
        
        attributeTitleLabel.considerEmptyString()
        attributeValueLabel.considerEmptyString()
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
        
        attributeTitleLabel.considerEmptyString()
        attributeValueLabel.considerEmptyString()
    }
    
    var firstResponder: UIView? {
        
        return attributeValueLabel
    }
}

extension PopupAttributeDateCell: StyledFirstResponderLabelDelegate {
    
    func inputViewForStyledFirstResponderLabel(_ label: StyledFirstResponderLabel) -> UIView? {
        
        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = .date
        datePickerView.addTarget(self, action: #selector(PopupAttributeDateCell.datePickerValueChanged(sender:)), for: .valueChanged)
        
        datePickerView.reloadInputViews()
        
        if let date = value.raw as? Date {
            datePickerView.date = date
        }
        else {
            datePickerValueChanged(sender: datePickerView)
        }
        
        delegate?.popupAttributeCell(self, didBecomeFirstResponder: attributeValueLabel)
        
        return datePickerView
    }
    
    @objc func datePickerValueChanged(sender: UIDatePicker) {
        
        if let formatted = delegate?.popupAttributeCell(self, valueDidChange: sender.date) {
            
            self.value = (formatted, sender.date)
            self.attributeValueLabel.text = formatted
        }
    }
}
