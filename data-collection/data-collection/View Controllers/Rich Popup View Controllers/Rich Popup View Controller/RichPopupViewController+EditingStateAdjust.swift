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

extension RichPopupViewController {
    
    func adjustViewControllerForEditingState() {
        
        defer {
            tableView.reloadData()
        }
        
        if popupEditButton != nil {
            popupEditButton?.title = popupManager.isEditing ? "Done" : "Edit"
        }
        
        guard isRootViewController else {
            return
        }
        
        if popupManager.isEditing {
            self.navigationItem.leftBarButtonItem?.style = .plain
            self.navigationItem.leftBarButtonItem?.title = "Cancel"
        }
        else {
            self.navigationItem.leftBarButtonItem?.style = .done
            self.navigationItem.leftBarButtonItem?.title = "Dismiss"
        }
    }
}
