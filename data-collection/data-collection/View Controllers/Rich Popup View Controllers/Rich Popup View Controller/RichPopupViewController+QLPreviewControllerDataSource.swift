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

import QuickLook

extension RichPopupViewController: QLPreviewControllerDataSource {
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return attachmentsViewController.popupAttachmentsManager.attachmentsCount
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        
        // Allow the popup attachments manager to determine if the attachment is `AGSLoadable` and to load it.
        do {
            try attachmentsViewController.popupAttachmentsManager.loadAttachment(at: index)
        }
        catch {
            assertionFailure("Index out of range of popup attachment manager.")
        }
        
        // Return the attachment for a given index.
        return attachmentsViewController.popupAttachmentsManager.attachment(at: index)!
    }
}
