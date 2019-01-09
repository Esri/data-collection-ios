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
import ArcGIS

class PopupAttributeDomainCell: UITableViewCell {
    
    var domain: AGSCodedValueDomain?
    
    private var title: String = ""
    
    @IBOutlet weak var attributeTitleLabel: UILabel!
    
    private var value: AttributeValue = ("", nil)
    
    @IBOutlet weak var attributeValueLabel: StyledFirstResponderLabel! {
        didSet {
            attributeValueLabel.delegate = self
        }
    }
    
    var delegate: PopupAttributeCellDelegate?
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        attributeValueLabel.isUserInteractionEnabled = editing
    }
}

extension PopupAttributeDomainCell: PopupAttributeCell {
    
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

extension PopupAttributeDomainCell: StyledFirstResponderLabelDelegate {
    
    func inputViewForStyledFirstResponderLabel(_ label: StyledFirstResponderLabel) -> UIView? {
        
        guard domain != nil else { return nil }
        
        // The picker view is substituted in place of a keyboard.
        let pickerView = UIPickerView()
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        // Load picker view components, so we can select the row for the current value.
        pickerView.reloadAllComponents()
        
        if let row = domain?.codedValues.firstIndex(where: { (value) -> Bool in
            value.name == self.attributeValueLabel.text
        }){
            // Select current value.
            pickerView.selectRow(row, inComponent: 0, animated: false)
        }
        else if value.raw == nil, let domain = domain, !domain.codedValues.isEmpty {
            // If no selection, select first option as default.
            self.pickerView(pickerView, didSelectRow: 0, inComponent: 0)
        }
        
        delegate?.popupAttributeCell(self, didBecomeFirstResponder: attributeValueLabel)
        
        return pickerView
    }
}

extension PopupAttributeDomainCell: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return domain?.codedValues.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return domain?.codedValues[row].name ?? ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if let domain = domain {
            attributeValueLabel.text = domain.codedValues[row].name
            delegate?.popupAttributeCell(self, valueDidChange: domain.codedValues[row].code)
        }
    }
}
