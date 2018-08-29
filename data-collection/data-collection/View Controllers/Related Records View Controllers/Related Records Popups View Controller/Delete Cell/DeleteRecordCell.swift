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
    
    private let stackView = UIStackView()
    private let deleteLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .none
        
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 6.0
        
        deleteLabel.textColor = appColors.invalid
        deleteLabel.font = appFonts.tableCellValue
        deleteLabel.textAlignment = .center
        deleteLabel.numberOfLines = 1
        deleteLabel.text = "Delete"
        
        stackView.addArrangedSubview(deleteLabel)
        
        contentView.addSubviewAndConstrainToView(stackView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(forPopup popup: AGSPopup) {
        deleteLabel.text = "Delete \(popup.recordType.rawValue.capitalized)"
    }
}
