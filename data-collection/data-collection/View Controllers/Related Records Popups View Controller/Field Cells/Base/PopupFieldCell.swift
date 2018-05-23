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

import ArcGIS
import UIKit

protocol PopupFieldCellProtocol {
    var field: AGSPopupField? { get set }
    var popupManager: AGSPopupManager? { get set }
    func updateCell()
}

class PopupFieldCellBase<ValueType>: UITableViewCell, PopupFieldCellProtocol {
    
    var field: AGSPopupField?
    weak var popupManager: AGSPopupManager?
    
    internal var stackView = UIStackView()
    internal var titleLabel = UILabel()
    internal var valueLabel = UILabel()
    
    var valueEditable: ValueType? {
        didSet {
            validatePopupValue()
        }
    }
    
    var fieldType: AGSFieldType? {
        guard let field = field, let popupManager = popupManager else {
            return nil
        }
        return popupManager.fieldType(for: field)
    }
    
    var domain: AGSDomain? {
        guard let field = field, let popupManager = popupManager else {
            return nil
        }
        return popupManager.domain(for: field)
    }
    
    func updateCell() { }
    
    override func prepareForReuse() {

        field = nil
        popupManager = nil

        updateCell()
    }
    
    func validatePopupValue() {
        
        guard let field = field, let popupManager = popupManager else {
            prepareForReuse()
            return
        }
        
        do {
            try popupManager.updateValue(valueEditable, field: field)
            titleLabel.textColor = AppConfiguration.appColors.tableCellTitle
        }
        catch {
            titleLabel.textColor = .red
            print(error)
        }
    }
}

class PopupFieldCell<ViewType: UIView, ValueType>: PopupFieldCellBase<ValueType> {
    
    override func updateCell() {
        
        layoutSubviews()
        popuplateCellForPopupField()
    }
    
    var isValueEditViewEnabled: Bool {
        return true
    }
    
    internal var valueEditView: ViewType?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 6.0
        contentView.addSubview(stackView)
        contentView.constrainToBounds(stackView)
        
        titleLabel.textColor = AppConfiguration.appColors.tableCellTitle
        titleLabel.font = AppConfiguration.appFonts.tableCellTitle
        titleLabel.sizeToFit()
        titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight).isActive = true
        stackView.addArrangedSubview(titleLabel)
        
        valueLabel.textColor = AppConfiguration.appColors.tableCellValue
        valueLabel.font = AppConfiguration.appFonts.tableCellValue
        valueLabel.numberOfLines = 0
        valueLabel.sizeToFit()
        
        insertValueLabel()
    }

    public func insertValueLabel() {
        
        if !stackView.subviews.contains(valueLabel)  {
            stackView.addArrangedSubview(valueLabel)
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: valueLabel.font.lineHeight).isActive = true
        }
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Popup Field Cells do not support init from Storyboards.")
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
    
    public func popuplateCellForPopupField() {
        
        guard let field = field, let popupManager = popupManager else {
            titleLabel.text = ""
            valueLabel.text = ""
            return
        }
        
        titleLabel.text = field.label
        valueLabel.text = popupManager.formattedValue(for: field)
        
        titleLabel.considerEmptyStringForStackView()
        valueLabel.considerEmptyStringForStackView()
    }
}
