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

class PopupNewRelatedRecordCell: UITableViewCell {
    
    @IBOutlet weak var newRelatedRecordTitleLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let add = UIButton(type: .contactAdd)
        add.isUserInteractionEnabled = false
        accessoryView = add
        editingAccessoryView = add
    }

    func setTableName(_ tableName: String?) {
        
        if let name = tableName {
            newRelatedRecordTitleLabel.text = String(format: "Add %@", name)
        }
        else {
            newRelatedRecordTitleLabel.text = String(format: "Add Record")
        }
    }
}
