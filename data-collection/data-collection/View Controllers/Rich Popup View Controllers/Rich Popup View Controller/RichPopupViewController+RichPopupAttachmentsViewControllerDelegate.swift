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

import Foundation
import QuickLook

extension RichPopupViewController: RichPopupAttachmentsViewControllerDelegate {
    
    func attachmentsViewControllerDidRequestAddAttachment(_ attachmentsViewController: RichPopupAttachmentsViewController) {
        
        if !isEditing {
            let alert = UIAlertController(
                title: nil,
                message: "To add an attachment, you need to start an editing session. Start editing?",
                preferredStyle: .alert
            )
            let edit = UIAlertAction(title: "Edit", style: .default) { [weak self] (_) in
                guard let self = self else { return }
                // 1. Start editing session
                self.setEditing(true, animated: true)
                // 2. Build requests
                self.imagePickerPermissions.request(options: [.photo, .library])
            }
            alert.addAction(.cancel())
            alert.addAction(edit)
            showAlert(alert, animated: true, completion: nil)
        }
        else {
            // Request, straight away.
            imagePickerPermissions.request(options: [.photo, .library])
        }
    }
    
    func attachmentsViewController(_ attachmentsViewController: RichPopupAttachmentsViewController, selectedEditStagedAttachment attachment: RichPopupStagedAttachment) {
        
        // Cache staged attachment to be edited.
        EphemeralCache.shared.setObject(
            attachment,
            forKey: "RichPopupEditStagedPhotoAttachment.EphemeralCacheKey"
        )
        
        // Perform segue to view controller that will allow editing of the staged attachment.
        self.performSegue(withIdentifier: "RichPopupEditStagedPhotoAttachment", sender: self)
    }
    
    func attachmentsViewController(_ attachmentsViewController: RichPopupAttachmentsViewController, selectedViewAttachmentAtIndex index: Int) {
        
        disableUserInteraction(status: nil)
        
        previewController.reloadData()
        
        previewController.currentPreviewItemIndex = index
        
        self.present(self.previewController, animated: true) { [weak self] in
            
            guard let self = self else { return }
            
            self.enableUserInteraction()
        }
    }
}
