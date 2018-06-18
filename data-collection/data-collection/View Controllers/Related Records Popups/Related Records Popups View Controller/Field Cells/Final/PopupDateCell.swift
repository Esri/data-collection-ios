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

final class PopupDateCell: PopupTextFieldCell {
    
    public override func insertValueEditView() {
        
        super.insertValueEditView()
        
        valueEditView?.addTarget(self, action: #selector(PopupDateCell.textFieldEditingDidBegin(_:)), for: .editingDidBegin)
    }
    
    @objc func textFieldEditingDidBegin(_ textField: UITextField) {
        
        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = .date
        valueEditView?.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(PopupDateCell.datePickerValueChanged(sender:)), for: .valueChanged)
    }
    
    @objc func datePickerValueChanged(sender: UIDatePicker) {
        
        updateCellValue(sender.date)

        guard let field = field else {
            valueEditView?.text = sender.date.formattedString
            return
        }
        
        valueEditView?.text = popupManager?.formattedValue(for: field) ?? sender.date.formattedString
    }
}
