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


class PopupEditableFieldCell<ViewType: UIView>: PopupReadonlyFieldCell {
    
    internal var valueEditView: ViewType?

    override func prepareForReuse() {
        
        field = nil
        popupManager = nil
        
        updateCell()
    }
    
    func updateValue(_ value: Any?) {
        
        guard let popupManager = popupManager, let field = field else {
            return
        }
        
        var isValid: Bool = true
        
        defer {
            titleLabel.textColor = isValid ? AppConfiguration.appColors.tableCellTitle : .red
        }
        
        do {
            try popupManager.updateValue(value, field: field)
        }
        catch {
            print(error)
            isValid = false
        }
    }
    
    override func updateCell() {
        
        layoutSubviews()
        popuplateCellForPopupField()
    }
    
    public func removeValueLabel() {
        
        if stackView.subviews.contains(valueLabel) {
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: valueLabel.font.lineHeight).isActive = false
            stackView.removeArrangedSubview(valueLabel)
            valueLabel.removeFromSuperview()
        }
    }
    
    public func insertValueEditView() {
        
        guard let view = valueEditView else {
            return
        }
        
        if !stackView.subviews.contains(view)  {
            stackView.addArrangedSubview(view)
        }
    }
    
    public func removeValueEditView() {
        
        guard let view = valueEditView else {
            return
        }
        
        if stackView.subviews.contains(view) {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
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
