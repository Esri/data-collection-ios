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

class PopupReadonlyFieldCell: UITableViewCell, PopupFieldCellProtocol {
    
    var field: AGSPopupField?
    weak var popupManager: PopupRelatedRecordsManager?
    
    internal var stackView = UIStackView()
    internal var titleLabel = UILabel()
    internal var valueLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 6.0

        contentView.addSubviewAndConstrainToView(stackView)
        
        titleLabel.textColor = appColors.tableCellTitle
        titleLabel.font = appFonts.tableCellTitle
        titleLabel.sizeToFit()
        titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight).isActive = true
        stackView.addArrangedSubview(titleLabel)
        
        valueLabel.textColor = appColors.tableCellValue
        valueLabel.font = appFonts.tableCellValue
        valueLabel.numberOfLines = 0
        valueLabel.sizeToFit()
        
        insertValueLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func insertValueLabel() {
        
        if !stackView.subviews.contains(valueLabel)  {
            stackView.addArrangedSubview(valueLabel)
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: valueLabel.font.lineHeight).isActive = true
        }
    }
    
    func updateCellContent() {
        
        popuplateCellForPopupField()
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
