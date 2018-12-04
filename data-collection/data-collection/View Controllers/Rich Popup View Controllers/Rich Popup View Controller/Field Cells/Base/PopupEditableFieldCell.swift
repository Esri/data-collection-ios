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

/// A generic subclass of `PopupReadonlyFieldCell` that allows the cell to be configured to view or edit a pop-up field.
class PopupEditableFieldCell<ViewType: UIView>: PopupReadonlyFieldCell {
    
    internal var valueEditView: ViewType?

    override func prepareForReuse() {
        super.prepareForReuse()
        
        field = nil
        popupManager = nil
        
        updateCellContent()
    }
    
    func updateCellValue(_ value: Any?) {
        
        guard let popupManager = popupManager, let field = field else {
            return
        }
        
        try? popupManager.updateValue(value, field: field)

        checkCellValidity()
    }
    
    override func updateCellContent() {
        
        layoutSubviews()
        popuplateCellForPopupField()
    }
    
    override public func popuplateCellForPopupField() {
        
        super.popuplateCellForPopupField()
        
        checkCellValidity()
    }
    
    public func checkCellValidity() {
        
        guard let popupManager = popupManager, let field = field else {
            return
        }
        
        if let error = popupManager.validationError(for: field) {
            titleLabel.textColor = .destructive
            titleLabel.text = String(format: "%@: %@", field.label, error.localizedDescription)
        }
        else {
            titleLabel.textColor = .gray
            titleLabel.text = field.label
        }
    }
    
    public func removeValueLabel() {
        
        valueLabel.isHidden = true
    }
    
    public func insertValueEditView() {
        
        guard let view = valueEditView else {
            return
        }
        
        if !stackView.subviews.contains(view)  {
            stackView.addArrangedSubview(view)
        }
        
        view.isHidden = false
    }
    
    public func removeValueEditView() {
        
        guard let view = valueEditView else {
            return
        }
        
        view.isHidden = true
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        if let popupManager = popupManager, popupManager.isEditing {
            removeValueLabel()
            insertValueEditView()
        }
        else {
            removeValueEditView()
            insertValueLabel()
        }
    }
    
    public var keyboardType: UIKeyboardType {
        return .default
    }
}
