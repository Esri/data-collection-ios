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
import ArcGIS

protocol RichPopupAttachmentsViewControllerDelegate: AnyObject {
    func attachmentsViewControllerDidRequestAddAttachment(_ attachmentsViewController: RichPopupAttachmentsViewController)
    func attachmentsViewController(_ attachmentsViewController: RichPopupAttachmentsViewController, selectedEditStagedAttachment attachment: RichPopupStagedAttachment)
    func attachmentsViewController(_ attachmentsViewController: RichPopupAttachmentsViewController, selectedViewAttachmentAtIndex index: Int)
}

class RichPopupAttachmentsViewController: UITableViewController {
    
    var popupManager: RichPopupManager! {
        didSet {
            popupManager.richPopupAttachmentManager!.delegate = self
        }
    }
    
    var popupAttachmentsManager: RichPopupAttachmentsManager {
        return popupManager.richPopupAttachmentManager!
    }
    
    weak var delegate: RichPopupAttachmentsViewControllerDelegate?
    
    static let byteCountFormatter = ByteCountFormatter()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        popupAttachmentsManager.load { [weak self] (error) in
            
            guard let self = self else { return }
            
            if let error = error {
                self.present(simpleAlertMessage: "Something went wrong loading attachments. \(error.localizedDescription)")
            }
            
            self.tableView.reloadData()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if popupManager.attachmentsShowOnly || popupManager.attachmentsShowAndEdit {
            self.tableView.reloadData()
        }
    }
    
    func addAttachment(_ attachment: RichPopupStagedAttachment) {
        
        popupAttachmentsManager.add(stagedAttachment: attachment)
        
        tableView.reloadData()
    }
    
    // MARK: configured section adjustment
    
    enum AttachmentsTableSection {
        case addAttachment, attachmentsList
    }
    
    func activeAttachmentsTableSections() -> [AttachmentsTableSection] {
        
        var sections = [AttachmentsTableSection]()
        
        if popupManager.shouldAllowEditAttachments {
            sections.append(.addAttachment)
        }
        
        if popupManager.shouldShowAttachments {
            sections.append(.attachmentsList)
        }
        
        return sections
    }
    
    func adjustedAttachmentsTableSection(for section: Int) -> AttachmentsTableSection? {
        
        let sections = activeAttachmentsTableSections()
        
        guard section < sections.count else {
            assertionFailure("Section \(section) outside the active attachments table sections range 0..<\(sections.count)")
            return nil
        }
        
        return sections[section]
    }
}

