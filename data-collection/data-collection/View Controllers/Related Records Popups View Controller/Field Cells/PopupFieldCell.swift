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

class PopupFieldCell<K: UIView>: UITableViewCell {
    
    var field: AGSPopupField! {
        didSet {
            updateForPopupField()
        }
    }
    
    weak var popupManager: AGSPopupManager!
    
    var fieldType: AGSFieldType {
        return popupManager.fieldType(for: field)
    }
    
    internal var stackView = UIStackView()
    internal var titleLabel = UILabel()
    internal var valueLabel = UILabel()
    internal var valueEditView: K?
    
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
        valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: valueLabel.font.lineHeight).isActive = true
        stackView.addArrangedSubview(valueLabel)
    }
    
    public func removeValueLabel() {
        
        stackView.removeArrangedSubview(valueLabel)
        valueLabel.removeFromSuperview()
    }
    
    public func addValueLabel() {
        
        stackView.addArrangedSubview(valueLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Popup Field Cells do not support init from Storyboards.")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // updates to subviews
    }
    
    public var keyboardType: UIKeyboardType {
        return .default
    }
    
    public func updateForPopupField() {
        
        titleLabel.text = field.label
        valueLabel.text = popupManager.formattedValue(for: field)
        
        titleLabel.considerEmptyStringForStackView()
        valueLabel.considerEmptyStringForStackView()
    }
}
