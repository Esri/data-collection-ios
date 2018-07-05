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

import Foundation
import ArcGIS

class DeleteRecordCell: UITableViewCell {
    
    private weak var stackView: UIStackView?
    private weak var deleteLabel: UILabel?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .none
        
        let containingStackView = UIStackView()
        containingStackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        containingStackView.isLayoutMarginsRelativeArrangement = true
        containingStackView.axis = .vertical
        containingStackView.alignment = .fill
        containingStackView.spacing = 6.0
        
        let containedDeleteLabel = UILabel()
        containedDeleteLabel.textColor = AppConfiguration.appColors.invalid
        containedDeleteLabel.font = AppConfiguration.appFonts.tableCellValue
        containedDeleteLabel.textAlignment = .center
        containedDeleteLabel.numberOfLines = 1
        containedDeleteLabel.text = "Delete"
        
        containingStackView.addArrangedSubview(containedDeleteLabel)
        
        contentView.addSubview(containingStackView)
        contentView.constrainToBounds(containingStackView)
        
        stackView = containingStackView
        deleteLabel = containedDeleteLabel
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(forPopup popup: AGSPopup) {
        
        guard let recordType = popup.recordType else {
            deleteLabel?.text = "Delete"
            return
        }
        
        deleteLabel?.text = "Delete \(recordType.rawValue.capitalized)"
    }
}
