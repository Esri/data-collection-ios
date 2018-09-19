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
    weak var table: AGSArcGISFeatureTable?
    
    public var popup: AGSPopup?
    public var maxAttributes: Int = 3
    public var editingPopup: Bool = false
    
    private let stackView = UIStackView()

    private var attributes = [(title: UILabel, value: UILabel)]()
    private var emptyCellLabel: UILabel?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .disclosureIndicator
        
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.alignment = .fill

        stackView.spacing = 6.0

        contentView.addStackviewAndConstrainToEdges(stackView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setAccessoryViewNone() {
        accessoryType = .none
        accessoryView = nil
    }
    
    private func setAccessoryViewDisclosureIndicator() {
        accessoryType = .disclosureIndicator
        accessoryView = nil
    }
    
    private func setAccessoryViewAddIndicator() {
        let button = UIButton(type: .contactAdd)
        button.tintColor = .primary
        button.isUserInteractionEnabled = false
        accessoryView = button
    }
    
    func updateCellContent() {

        guard let manager = popup?.asManager else {
            updateEmptyCellContent()
            return
        }
        
        // 0. Clear empty cell label
        if emptyCellLabel != nil {
            stackView.removeArrangedSubview(emptyCellLabel!)
            emptyCellLabel!.removeFromSuperview()
            emptyCellLabel = nil
        }
        
        // 1. Determine n attributes not to exceed max attributes
        let nAttributes = min(maxAttributes, manager.displayFields.count)
        
        // 2. Adjust for correct n attributes
        if attributes.count < nAttributes {
            
            while attributes.count != nAttributes {
                
                let titleLabel = UILabel()
                titleLabel.numberOfLines = 1
                titleLabel.textColor = .tableCellTitle
                titleLabel.font = .tableCellTitle
                titleLabel.adjustsFontForContentSizeCategory = true
                stackView.addArrangedSubview(titleLabel)
                
                let valueLabel = UILabel()
                valueLabel.numberOfLines = 0
                valueLabel.textColor = .tableCellValue
                valueLabel.font = .tableCellValue
                valueLabel.adjustsFontForContentSizeCategory = true
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
                
                stackView.removeArrangedSubview(last.title)
                last.title.removeFromSuperview()
                stackView.removeArrangedSubview(last.value)
                last.value.removeFromSuperview()
            }
        }
        
        // 3. Populate attribute labels with content from popup (manager)
        var popupIndex = 0
        
        for attribute in attributes {
            
            let titleLabel = attribute.title
            titleLabel.text = manager.labelTitle(fieldIndex: popupIndex)
            let valueLabel = attribute.value
            valueLabel.text = manager.nextFieldStringValue(fieldIndex: &popupIndex)
            
            // TODO workout constraints issue
            titleLabel.considerEmptyString()
            valueLabel.considerEmptyString()
        }
        
        setAccessoryViewDisclosureIndicator()        
    }
    
    private func updateEmptyCellContent() {
        
        for attribute in attributes {
            stackView.removeArrangedSubview(attribute.title)
            attribute.title.removeFromSuperview()
            stackView.removeArrangedSubview(attribute.value)
            attribute.value.removeFromSuperview()
        }
        
        attributes.removeAll()
        
        if emptyCellLabel == nil {
            emptyCellLabel = UILabel()
            emptyCellLabel?.numberOfLines = 1
            emptyCellLabel?.font = .tableCellTitle
            emptyCellLabel?.adjustsFontForContentSizeCategory = true
            stackView.addArrangedSubview(emptyCellLabel!)
        }
        
        guard let info = relationshipInfo else {
            setAccessoryViewNone()
            emptyCellLabel?.text = nil
            return
        }
        
        if info.isManyToOne {
            if editingPopup {
                setAccessoryViewDisclosureIndicator()
                emptyCellLabel?.textColor = info.isComposite ? .invalid : .tableCellTitle
                emptyCellLabel?.text = "Select \(table?.tableName ?? "related record")"
            }
            else {
                setAccessoryViewNone()
                emptyCellLabel?.textColor = .missing
                emptyCellLabel?.text = "(Empty \(table?.tableName ?? "related") record)"
            }
        }
        else {
            if popup == nil {
                setAccessoryViewAddIndicator()
            }
            else {
                setAccessoryViewDisclosureIndicator()
            }
            emptyCellLabel?.textColor = .primary
            emptyCellLabel?.text = "Add \(table?.tableName ?? "related record")"
        }
    }
}
