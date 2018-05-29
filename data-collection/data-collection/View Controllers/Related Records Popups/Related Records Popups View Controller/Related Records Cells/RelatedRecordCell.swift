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

class RelatedRecordCell: UITableViewCell {
    
    weak var relationshipInfo: AGSRelationshipInfo?
    
    public var popup: AGSPopup? {
        didSet {
            guard let feature = popup?.geoElement as? AGSArcGISFeature else {
                update()
                return
            }
            feature.load { [weak self] (error) in
                self?.update()
            }
        }
    }
    
    public var maxAttributes: Int = 3 {
        didSet {
            update()
        }
    }
    
    private var attributes = [(UILabel, UILabel)]()
    
    private var stackView = UIStackView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .disclosureIndicator
        
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 6.0
        contentView.addSubview(stackView)
        contentView.constrainToBounds(stackView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
    
    // TODO validity
    
    private func update() {
        
        guard let manager = popup?.asManager else {
            for attribute in attributes {
                stackView.removeArrangedSubview(attribute.0)
                attribute.0.removeFromSuperview()
                stackView.removeArrangedSubview(attribute.1)
                attribute.1.removeFromSuperview()
            }
            attributes.removeAll()
            return
        }
        
        let nAttributes = min(maxAttributes, manager.displayFields.count)
        
        if attributes.count < nAttributes {
            
            while attributes.count != nAttributes {
                
                let titleLabel = UILabel()
                titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
                titleLabel.textColor = .gray
                titleLabel.sizeToFit()
                titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight).isActive = true
                stackView.addArrangedSubview(titleLabel)
                
                let valueLabel = UILabel()
                valueLabel.numberOfLines = 0
                valueLabel.font = UIFont.preferredFont(forTextStyle: .body)
                valueLabel.sizeToFit()
                valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: valueLabel.font.lineHeight).isActive = true
                
                stackView.addArrangedSubview(valueLabel)
                
                attributes.append((titleLabel, valueLabel))
            }
        }
        else if attributes.count > nAttributes {
            
            while attributes.count != nAttributes {
                
                guard attributes.last != nil else {
                    break
                }
                
                let last = attributes.removeLast()
                
                // TODO consider how removing Auto Layout constraints
                
                stackView.removeArrangedSubview(last.0)
                last.0.removeFromSuperview()
                stackView.removeArrangedSubview(last.1)
                last.1.removeFromSuperview()
            }
        }
        
        var popupIndex = 0
        
        for attribute in attributes {
            
            let titleLabel = attribute.0
            titleLabel.text = manager.labelTitle(idx: popupIndex)
            let valueLabel = attribute.1
            valueLabel.text = manager.nextFieldStringValue(idx: &popupIndex)
            
            // TODO workout constraints issue
            titleLabel.considerEmptyStringForStackView()
            valueLabel.considerEmptyStringForStackView()
        }
    }
}
