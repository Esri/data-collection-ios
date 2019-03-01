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
import UIKit

extension RichPopupAttachmentsViewController /* UITableViewDataSource */ {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return activeAttachmentsTableSections().count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let adjustedSection = adjustedAttachmentsTableSection(for: section) else {
            return 0
        }

        switch adjustedSection {
        case .addAttachment:
            return 1
        case .attachmentsList:
            return popupAttachmentsManager.attachmentsCount
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = adjustedAttachmentsTableSection(for: indexPath.section)

        if section == .addAttachment {
            return tableView.dequeueReusableCell(withIdentifier: "PopupAddAttachmentCell", for: indexPath)
        }
        else if section == .attachmentsList {

            let cell = tableView.dequeueReusableCell(withIdentifier: "PopupAttachmentCell", for: indexPath) as! PopupAttachmentCell
            
            if let attachment = popupAttachmentsManager.attachment(at: indexPath.row) {
                
                // Attachment Image
                if let image = popupAttachmentsManager.cachedThumbnail(for: attachment) {
                    cell.attachmentImageView.image = image
                }
                else {
                    cell.attachmentImageView.image = attachment.type.icon
                    let size = max(cell.attachmentImageView.bounds.width, cell.attachmentImageView.bounds.height)
                    try? popupAttachmentsManager.generateThumbnail(for: attachment, size: Float(size))
                }
                
                // Attachment Name
                if let name = attachment.name, !name.isEmpty {
                    cell.nameLabel.text = name
                } else {
                    cell.nameLabel.text = "(no name)"
                }
                
                // Attachment Size
                if let attachment = attachment as? AGSPopupAttachment {
                    cell.sizeLabel.text = RichPopupAttachmentsViewController.byteCountFormatter.string(fromByteCount: Int64(attachment.actualSizeInBytes))
                    cell.editingAccessoryType = .none
                }
                else {
                    cell.sizeLabel.text = attachment.preferredSize.asTitle.lowercased()
                    cell.editingAccessoryType = .disclosureIndicator
                }
            }
            
            return cell
        }
        else {
            assertionFailure("Data source discrepancy.")
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if adjustedAttachmentsTableSection(for: section) == .attachmentsList, popupAttachmentsManager.hasStagedAttachments {
            return "Only new attachments can be edited."
        }
        else {
            return nil
        }
    }
}
