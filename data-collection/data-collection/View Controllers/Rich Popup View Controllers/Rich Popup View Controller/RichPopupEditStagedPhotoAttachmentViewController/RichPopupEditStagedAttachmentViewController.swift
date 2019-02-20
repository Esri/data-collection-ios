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

private extension Int {
    
    // Convenience static naming of table view sections.
    static let nameSection = 0
    static let preferredSizeSection = 1
}


private extension AGSPopupAttachmentSize {
    
    // This array of popup attachment sizes is used to layout the size options.
    // Note: This array must match the static table in the storyboard.
    static var tableViewMap: [AGSPopupAttachmentSize] {
        return [.small, .medium, .large, .extraLarge, .actual]
    }
}

class RichPopupEditStagedAttachmentViewController: UITableViewController, UITextFieldDelegate {
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // By default, this view controller assumes we're editing an image attachment.
        // If it's not, the view controller removes the statically built cells associated with attachment size,
        // leaving only the name field.
        if stagedAttachment.type != .image {
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Popuplate the form.
        updateTableForCurrent(stagedPhotoAttachment: stagedAttachment)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if attachmentNameTextField.isFirstResponder {
            attachmentNameTextField.resignFirstResponder()
        }
    }
    
    // MARK: Staged Attachment
    
    var stagedAttachment: RichPopupStagedAttachment!

    private func updateTableForCurrent(stagedPhotoAttachment attachment: RichPopupPreviewableAttachment) {
        
        attachmentNameTextField.text = attachment.name
        
        if let cell = cellForMappedAttachmentSize(attachment.preferredSize) {
            cell.accessoryType = .checkmark
        }
    }
    
    // MARK: Attachment Name Text Field
    
    @IBOutlet weak var attachmentNameTextField: UITextField!
    
    @IBAction func attachmentNameTextFieldDidChange(_ sender: Any) {
        
        if let textField = sender as? UITextField, textField == attachmentNameTextField {
            
            // Limit input to 40 characters.
            // The SDK truncates attachment names to 40 characters.
            if let text = textField.text, text.count > 40 {
                
                let offset = String.Index(encodedOffset: 40)
                
                let truncated = String(text[..<offset])
                
                attachmentNameTextField.text = truncated
            }
            
            stagedAttachment.name = attachmentNameTextField.text
        }
    }
    
    // MARK: Attachment Name Text Field Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        return true
    }
    
    // MARK: Table View Mapping
    
    private func cellForMappedAttachmentSize(_ desiredSize: AGSPopupAttachmentSize) -> UITableViewCell? {
        
        guard let currentIndex = AGSPopupAttachmentSize.tableViewMap.firstIndex(where: { (size) -> Bool in
            return size == desiredSize
        })
        else { return nil }
        
        let indexPath = IndexPath(row: currentIndex, section: .preferredSizeSection)
        
        return tableView.cellForRow(at: indexPath)
    }
    
    // MARK: Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == .preferredSizeSection {
            if let cell = tableView.cellForRow(at: indexPath) {
                
                // Set the selected value.
                stagedAttachment.preferredSize = AGSPopupAttachmentSize.tableViewMap[indexPath.row]
                
                // Store the selected value in `UserDefaults`.
                stagedAttachment.preferredSize.storeDefaultPopupAttachmentSize()
                
                // Indicate to the user the selection has been made.
                cell.accessoryType = .checkmark
            }
        }
        
        if attachmentNameTextField.isFirstResponder {
            attachmentNameTextField.resignFirstResponder()
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if indexPath.section == .preferredSizeSection {
            if let currentCell = cellForMappedAttachmentSize(stagedAttachment.preferredSize) {
                
                // Remove checkmark, preparing for new selection.
                currentCell.accessoryType = .none
            }
        }
        
        return indexPath
    }
    
    // MARK: Table View Data Source
    
    // Note: The default table view configuration is built in storyboard and is designed
    // for image attachments. Other attachment types can use this view controller for editing
    // but only the name field will be exposed.
    
    // The following two data source methods configure the table view for non-image attachment types.
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if stagedAttachment.type == .image {
            return super.numberOfSections(in: tableView)
        }
        else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if stagedAttachment.type == .image {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        else {
            return 1
        }
    }
}
