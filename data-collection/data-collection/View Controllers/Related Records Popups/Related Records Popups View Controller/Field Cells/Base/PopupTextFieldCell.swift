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

class PopupTextFieldCell: PopupEditableFieldCell<UITextField> {
    
    public override func insertValueEditView() {
        
        if valueEditView == nil {
            
            valueEditView = UITextField(frame: .zero)
            valueEditView?.textColor = AppConfiguration.appColors.tableCellValue
            valueEditView?.font = AppConfiguration.appFonts.tableCellValue
            valueEditView?.sizeToFit()
            valueEditView?.borderStyle = .roundedRect
            valueEditView?.keyboardType = keyboardType
        }

        valueEditView?.isEnabled = isValueEditable
        valueEditView?.addTarget(self, action: #selector(PopupTextFieldCell.textFieldDidChange(_:)), for: .editingChanged)
        valueEditView?.heightAnchor.constraint(greaterThanOrEqualToConstant: valueEditView?.frame.size.height ?? 25.0).isActive = true

        super.insertValueEditView()
    }
    
    public override func removeValueEditView() {
        
        valueEditView?.removeTarget(self, action: #selector(PopupTextFieldCell.textFieldDidChange(_:)), for: .editingChanged)
        valueEditView?.heightAnchor.constraint(greaterThanOrEqualToConstant: valueEditView?.frame.size.height ?? 25.0).isActive = false
        
        super.removeValueEditView()
    }
    
    override func popuplateCellForPopupField() {
        
        super.popuplateCellForPopupField()
        
        guard let field = field, let popupManager = popupManager else {
            valueEditView?.text = ""
            return
        }
        
        valueEditView?.text = popupManager.formattedValue(for: field)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {

        updateCellValue(textField.text)
    }
}
