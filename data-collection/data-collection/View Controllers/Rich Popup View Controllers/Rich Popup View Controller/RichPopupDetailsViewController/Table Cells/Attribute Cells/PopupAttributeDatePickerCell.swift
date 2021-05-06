// Copyright 2020 Esri
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

class PopupAttributeDatePickerCell: UITableViewCell {

    @IBOutlet weak var attributeTitleLabel: UILabel!
    // Label for viewing attribute date value
    @IBOutlet weak var attributeValueLabel: UILabel!
    // Date picker for editing attribute date value
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var indexPath = IndexPath(row: 0, section: 0)
    var delegate: PopupAttributeCellDelegate?
    
    private var title: String = ""
    private var value: AttributeValue = ("", nil)
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        datePicker.isHidden = !editing
        attributeValueLabel.isHidden = editing
        if editing && value.raw == nil {
            // set default value
            pickerValueDidChange(datePicker)
        }
    }
}

extension PopupAttributeDatePickerCell: PopupAttributeCell {
    
    func setTitle(_ title: String, value: AttributeValue) {
        
        // Title
        self.title = title
        attributeTitleLabel.text = self.title
        
        // Value
        self.value = value
        attributeValueLabel.text = self.value.formatted
        if let date = self.value.raw as? Date {
            datePicker.date = date
        }
        
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
    
    // This value is nil because the iOS 14 UIDatePicker is not displayed in the keyboard area,
    // iOS manages the responder chain for this UI element independently.
    var firstResponder: UIView? {
        nil
    }
}

extension PopupAttributeDatePickerCell {
    
    @IBAction func pickerValueDidChange(_ sender: UIDatePicker) {
        if let formatted = delegate?.popupAttributeCell(self, valueDidChange: sender.date, at: indexPath) {
            self.value = (formatted, sender.date)
            self.attributeValueLabel.text = formatted
        }
    }
}
