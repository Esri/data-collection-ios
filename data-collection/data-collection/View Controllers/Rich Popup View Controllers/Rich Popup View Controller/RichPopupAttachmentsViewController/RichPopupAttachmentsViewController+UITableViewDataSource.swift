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

extension RichPopupAttachmentsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if popupManager.attachmentsNoAccess {
            return 0
        }
        if popupManager.attachmentsShowOnly || popupManager.attachmentsEditOnly {
            return 1
        }
        else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard tableView.numberOfSections > 0 else { return 0 }
        
        if tableView.numberOfSections == 1 {
            if popupManager.attachmentsEditOnly {
                return 1
            }
            else {
                return popupAttachmentsManager.attachmentsCount
            }
        }
        else {
            if section == 0 {
                return 1
            }
            else {
                return popupAttachmentsManager.attachmentsCount
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0, popupManager.shouldAllowEditAttachments {
            return tableView.dequeueReusableCell(withIdentifier: "PopupAddAttachmentCell") as! PopupAddAttachmentCell
        }
        else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PopupAttachmentCell") as! PopupAttachmentCell
            
            if let attachment = popupAttachmentsManager.attachment(at: indexPath.row) {
                
                cell.attachmentImageView.image = attachment.type.icon
                
                let size = max(cell.attachmentImageView.bounds.width, cell.attachmentImageView.bounds.height)
                
                if let image = popupAttachmentsManager.cachedThumbnail(for: attachment) {
                    cell.attachmentImageView.image = image
                }
                else {
                    cell.attachmentImageView.image = attachment.type.icon
                    try? popupAttachmentsManager.generateThumbnail(for: attachment, size: Float(size))
                }
                
                let noName = "(no name)"
                
                if let name = attachment.name {
                    cell.nameLabel.text = !name.isEmpty ? name : noName
                }
                else {
                    cell.nameLabel.text = noName
                }
                
                if let attachment = attachment as? AGSPopupAttachment {
                    cell.sizeLabel.text = RichPopupAttachmentsViewController.byteCountFormatter.string(fromByteCount: Int64(attachment.actualSizeInBytes))
                    cell.accessoryType = .none
                    cell.editingAccessoryType = .none
                }
                else {
                    cell.sizeLabel.text = attachment.preferredSize.asTitle.lowercased()
                    cell.accessoryType = .none
                    cell.editingAccessoryType = .disclosureIndicator
                }
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section == tableView.numberOfSections - 1, popupAttachmentsManager.hasStagedAttachments {
            return "Only new attachments can be edited."
        }
        else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        if tableView.cellForRow(at: indexPath) is PopupAddAttachmentCell {
            return .none
        }
        else {
            return .delete
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return !(tableView.cellForRow(at: indexPath) is PopupAddAttachmentCell)
    }
}
