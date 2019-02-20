//// Copyright 2019 Esri
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


class PopupRelatedRecordCell: UITableViewCell {
    
    typealias RelatedRecordAttribute = (title: String, value: String?)
    
    private typealias RelatedRecordAttributeLabels = (title: UILabel, value: UILabel)
    
    private var attributeLabels = [RelatedRecordAttributeLabels]()
    
    @IBOutlet weak var stackView: UIStackView!
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableNameLabel?.text = missingValueTitleLabelForEdit()
        tableNameLabel?.textColor = editing ? .black : .lightGray
    }
    
    // Missing Record State
    
    private var tableNameLabel: UILabel?
    
    private var tableName: String?
    
    private func missingValueTitleLabelForEdit() -> String {
        
        if isEditing {
            return String(format: "Select %@", tableName ?? "Record")
        }
        else {
            return String(format: "(Missing %@)", tableName ?? "Record")
        }
    }
    
    func setMissingValueFor(tableName: String?) {
        
        self.tableName = tableName
        
        adjustForAttribute(count: 0)
        
        if tableNameLabel == nil {
            
            let label = UILabel()
            
            label.numberOfLines = 1
            label.textColor = .black
            label.font = .tableCellTitle
            label.adjustsFontForContentSizeCategory = true
            label.setContentCompressionResistancePriority(.required, for: .vertical)
            
            tableNameLabel = label
        }
        
        tableNameLabel!.text = missingValueTitleLabelForEdit()
        tableNameLabel!.considerEmptyString()
        
        stackView.addArrangedSubview(tableNameLabel!)
    }
    
    func setAttributes(_ attributes: [RelatedRecordAttribute]) {
        
        // Adjust for correct (n) attributes.
        adjustForAttribute(count: attributes.count)
        
        if let label = tableNameLabel {
            
            // Remove table name label
            stackView.removeArrangedSubview(label)
            label.removeFromSuperview()
            
            // Nullify references
            tableNameLabel = nil
            tableName = nil
        }
        
        // Populate attribute fields.
        for (index, attribute) in attributes.enumerated() {
            
            let labels = attributeLabels[index]
            
            labels.title.text = attribute.title
            labels.value.text = attribute.value
            
            labels.title.considerEmptyString()
            labels.value.considerEmptyString()
        }
    }
    
    private func adjustForAttribute(count: Int) {
        
        if count > self.attributeLabels.count {
            
            while count != self.attributeLabels.count {
                
                let titleLabel = UILabel()
                titleLabel.numberOfLines = 1
                titleLabel.textColor = .lightGray
                titleLabel.font = .tableCellTitle
                titleLabel.adjustsFontForContentSizeCategory = true
                titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
                stackView.addArrangedSubview(titleLabel)
                
                let valueLabel = UILabel()
                valueLabel.numberOfLines = 0
                valueLabel.textColor = .black
                valueLabel.font = .tableCellValue
                valueLabel.adjustsFontForContentSizeCategory = true
                valueLabel.setContentCompressionResistancePriority(.required, for: .vertical)
                stackView.addArrangedSubview(valueLabel)
                
                self.attributeLabels.append((titleLabel, valueLabel))
            }
        }
        else if count < self.attributeLabels.count {
            
            while count != self.attributeLabels.count {
                
                guard attributeLabels.last != nil else {
                    break
                }
                
                let last = attributeLabels.removeLast()
                
                stackView.removeArrangedSubview(last.title)
                last.title.removeFromSuperview()
                stackView.removeArrangedSubview(last.value)
                last.value.removeFromSuperview()
            }
        }
    }
}
