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

protocol RichPopupAttachmentsManagerDelegate: AnyObject {
    func richPopupAttachmentsManager(_ manager: RichPopupAttachmentsManager, generatedThumbnailForAttachment attachment: RichPopupPreviewableAttachment)
}

class RichPopupAttachmentsManager: AGSLoadableBase {
    
    private weak var popupManager: RichPopupManager?
    
    private var popupAttachmentsManager: AGSPopupAttachmentManager
    
    weak var delegate: RichPopupAttachmentsManagerDelegate?
    
    init?(richPopupManager: RichPopupManager) {
        
        guard let manager = richPopupManager.attachmentManager else { return nil }
        
        self.popupManager = richPopupManager
        
        self.popupAttachmentsManager = manager
    }
    
    // MARK: Loadable
    
    private var cancelableFetch: AGSCancelable?
    
    override func doCancelLoading() {
        
        cancelableFetch?.cancel()
        
        clear()
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        if retrying { clear() }
        
        guard let popupManager = popupManager else {
            loadDidFinishWithError(NSError.unknown)
            return
        }
        
        guard popupManager.shouldShowAttachments else {
            loadDidFinishWithError(NSError.invalidOperation)
            return
        }
        
        cancelableFetch = popupAttachmentsManager.fetchAttachments { [weak self] (_, error) in
            
            guard let self = self else { return }
            
            if let error = error {
                self.loadDidFinishWithError(error)
                return
            }
            
            self.fetchedAttachments = self.popupAttachmentsManager.filteredAndSortedAttachments()
            
            self.loadDidFinishWithError(nil)
        }
    }
    
    // MARK: Fetched and Staged Attachments
    
    private var fetchedAttachments = [AGSPopupAttachment]()
    
    private var stagedAttachments = [RichPopupStagedAttachment]()
    
    var hasStagedAttachments: Bool {
        return !stagedAttachments.isEmpty
    }
    
    @discardableResult
    func add(stagedAttachment: RichPopupStagedAttachment) -> Int {
        
        stagedAttachments.append(stagedAttachment)
        
        return stagedAttachments.endIndex
    }
    
    
    func deleteAttachment(at index: Int) -> Bool {
        
        assert(index < attachmentsCount, "Index \(index) out of range 0..<\(attachmentsCount).")
        
        guard index < attachmentsCount else { return false }
        
        if index < fetchedAttachments.endIndex {
            let attachment = fetchedAttachments.remove(at: index)
            popupAttachmentsManager.deleteAttachment(attachment)
        }
        else {
            let stagedIndex = index - fetchedAttachments.count
            stagedAttachments.remove(at: stagedIndex)
        }
        
        return true
    }
    
    func commitStagedAttachments() {
        
        // Add Staged Attachments
        let newAttachments = self.stagedAttachments
        
        newAttachments.forEach { (attachment) in

            if let photoAttachment = attachment as? RichPopupStagedPhotoAttachment {
                
                popupAttachmentsManager.addAttachmentAsJPG(with: photoAttachment.image,
                                                           name: photoAttachment.nameAsJPEG ?? "Image.jpeg",
                                                           preferredSize: photoAttachment.preferredSize)
            }
            else {
                
                popupAttachmentsManager.addAttachment(with: attachment.attachmentData,
                                                      name: attachment.name ?? "Attachment",
                                                      contentType: attachment.attachmentMimeType,
                                                      preferredSize: attachment.preferredSize)
            }
        }
        
        discardStagedAttachments()
    }
        
    func discardStagedAttachments() {
        
        fetchedAttachments = popupAttachmentsManager.filteredAndSortedAttachments()
        stagedAttachments.removeAll()
    }
    
    private func clear() {
        
        fetchedAttachments.removeAll()
        stagedAttachments.removeAll()
    }
    
    private class CachedImage: NSObject {
        
        let image: UIImage?
        
        init(_ image: UIImage?) {
            self.image = image
        }
    }
    
    private var thumbnailCache = NSCache<AnyObject, CachedImage>()
    
    func cachedThumbnail(for attachment: RichPopupPreviewableAttachment) -> UIImage? {
        
        if let cachedImage = thumbnailCache.object(forKey: attachment) {
            return cachedImage.image
        }
        else {
            return nil
        }
    }
    
    // MARK: Loading Attachment and Generating Thumbnails

    func generateThumbnail(for attachment: RichPopupPreviewableAttachment, size: Float) throws {
        
        guard thumbnailCache.object(forKey: attachment) == nil else {
            return
        }
        
        if let attachment = attachment as? AGSPopupAttachment {

            guard self.fetchedAttachments.contains(attachment) else {
                throw NSError.invalidOperation
            }
        }
        else if let attachment = attachment as? RichPopupStagedAttachment {
            
            guard self.stagedAttachments.contains(attachment) else {
                throw NSError.invalidOperation
            }
        }
        else {
            assertionFailure("Invalid popup attachment type.")
        }
        
        attachment.generateThumbnail(withSize: size, scaleMode: .aspectFill) { [weak self] (image) in
            
            guard let self = self else { return }
            
            let cachedImage = CachedImage(image)
            
            self.thumbnailCache.setObject(cachedImage, forKey: attachment)
            
            self.delegate?.richPopupAttachmentsManager(self, generatedThumbnailForAttachment: attachment)
        }
    }
    
    func loadAttachment(at index: Int) throws {
        
        guard let attachment = attachment(at: index) else {
            throw NSError.invalidOperation
        }
        
        if let attachment = attachment as? AGSLoadable {
            attachment.load(completion: nil)
        }
    }
}

extension RichPopupAttachmentsManager {
    
    var attachmentsCount: Int {
        return fetchedAttachments.count + stagedAttachments.count
    }
    
    func attachment(at index: Int) -> RichPopupPreviewableAttachment? {
            
        guard index < attachmentsCount else { return nil }
        
        if index < fetchedAttachments.endIndex {
            return fetchedAttachments[index]
        }
        else {
            let stagedIndex = index - fetchedAttachments.count
            return stagedAttachments[stagedIndex]
        }
    }
    
    func indexPathFor(attachment: RichPopupPreviewableAttachment) -> IndexPath? {
        
        assert(popupManager != nil, "There is no reason a popup manager should not be present.")
        
        guard let popupManager = popupManager else {
            return nil
        }
        
        let section: Int
        
        // Section
        
        if popupManager.attachmentsShowOnly {
            section = 0
        }
        else if popupManager.attachmentsShowAndEdit {
            section = 1
        }
        else {
            return nil
        }
        
        var row: Int = -1
        
        // Row
        
        if let attachment = attachment as? AGSPopupAttachment {
            
            if let index = fetchedAttachments.firstIndex(of: attachment) {
                row = index
            }
            else {
                return nil
            }
        }
        else if let attachment = attachment as? RichPopupStagedAttachment {
            
            if let index = stagedAttachments.firstIndex(of: attachment) {
                row = index + fetchedAttachments.count
            }
            else {
                return nil
            }
        }
        
        return IndexPath(row: row, section: section)
    }
}
