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

import UIKit
import ArcGIS

final class PopupCodedValueCell: PopupTextFieldCell, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // TODO init with value
    
    public override func insertValueEditView() {
        
        super.insertValueEditView()
        
        valueEditView?.addTarget(self, action: #selector(PopupCodedValueCell.textFieldEditingDidBegin(_:)), for: .editingDidBegin)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        guard let codedValueDomain = domain as? AGSCodedValueDomain else {
            return 0
        }
        
        return codedValueDomain.codedValues.count
    }
    
    @objc func textFieldEditingDidBegin(_ textField: UITextField) {
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        valueEditView?.inputView = pickerView
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        guard let codedValueDomain = domain as? AGSCodedValueDomain else {
            return nil
        }
        
        return codedValueDomain.codedValues[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        guard let codedValueDomain = domain as? AGSCodedValueDomain else {
            return
        }
        
        updateValue(codedValueDomain.codedValues[row].code)
        
        valueEditView?.text = codedValueDomain.codedValues[row].name
    }
}

