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

class PopupTextViewCell: PopupEditableFieldCell<UITextView>, UITextViewDelegate {
    
    var isRichText: Bool = false
    
    var viewHeight: CGFloat {
        return 120.0
    }
    
    public override func insertValueEditView() {
        
        if valueEditView == nil {
            
            valueEditView = UITextView(frame: .zero)
            valueEditView?.textColor = appColors.tableCellValue
            valueEditView?.font = .tableCellValue
            valueEditView?.sizeToFit()
            valueEditView?.stylizeBorder()
            valueEditView?.keyboardType = keyboardType
        }

        valueEditView?.isEditable = isValueEditable
        valueEditView?.delegate = self
        valueEditView?.heightAnchor.constraint(greaterThanOrEqualToConstant: viewHeight).isActive = true

        super.insertValueEditView()
    }
    
    public override func removeValueEditView() {
        
        valueEditView?.delegate = nil
        valueEditView?.heightAnchor.constraint(greaterThanOrEqualToConstant: viewHeight).isActive = false
        
        super.removeValueEditView()
    }
    
    override func popuplateCellForPopupField() {
        
        super.popuplateCellForPopupField()
        
        guard let field = field, let popupManager = popupManager else {
            
            if isRichText {
                valueEditView?.attributedText = NSAttributedString(string: "")
            }
            else {
                valueEditView?.text = ""
            }
            return
        }
        
        if isRichText {
            valueEditView?.attributedText = NSAttributedString(string: popupManager.formattedValue(for: field))
        }
        else {
            valueEditView?.text = popupManager.formattedValue(for: field)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        if let field = field, field.stringFieldOption == .richText {
            updateCellValue(textView.attributedText)
        }
        else {
            updateCellValue(textView.text)
        }
    }
}
