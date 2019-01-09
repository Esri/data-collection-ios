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

import ArcGIS

extension RichPopupViewController: RichPopupSelectRelatedRecordViewControllerDelegate {
    
    func richPopupSelectRelatedRecordViewController(_ richPopupSelectRelatedRecordViewController: RichPopupSelectRelatedRecordViewController, didSelectPopup popup: AGSPopup) {
        
        navigationController?.popViewController(animated: true)
        
        // Stages the new relation. (Does not yet commit the staged record.)
        do {
            try popupManager.update(manyToOne: popup)
        }
        catch {
            present(simpleAlertMessage: "Something went wrong editing the related record. \(error.localizedDescription)")
        }
    }
}
