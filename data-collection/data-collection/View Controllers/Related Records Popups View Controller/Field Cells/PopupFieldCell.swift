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
    
    weak var popupManager: AGSPopupManager?
    
    private var stackView = UIStackView()
    private var titleLabel = UILabel()
    private var valueLabel = UILabel()
    private var valueEditView: K?
    
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
        NSLayoutConstraint.activate([ titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight) ])
        stackView.addArrangedSubview(titleLabel)
        
        valueLabel.textColor = AppConfiguration.appColors.tableCellValue
        valueLabel.font = AppConfiguration.appFonts.tableCellValue
        valueLabel.numberOfLines = 0
        valueLabel.sizeToFit()
        NSLayoutConstraint.activate([ valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: valueLabel.font.lineHeight) ])
        stackView.addArrangedSubview(valueLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // updates to subviews
    }
    
    public func updateForPopupField() {
        
        titleLabel.text = field.label
        valueLabel.text = popupManager?.formattedValue(for: field)
        
        titleLabel.considerEmptyStringForStackView()
        valueLabel.considerEmptyStringForStackView()
    }
}
