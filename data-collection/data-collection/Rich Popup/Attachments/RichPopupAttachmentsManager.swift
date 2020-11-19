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
import QuickLook

protocol RichPopupAttachmentsManagerDelegate: AnyObject {
    func richPopupAttachmentsManager(_ manager: RichPopupAttachmentsManager, generatedThumbnailForAttachment attachment: RichPopupPreviewableAttachment)
}

class RichPopupAttachmentsManager: AGSLoadableBase {
    
    private weak var popupManager: RichPopupManager?
    
    private var popupAttachmentsManager: AGSPopupAttachmentManager
    
    weak var delegate: RichPopupAttachmentsManagerDelegate?
    
    init?(richPopupManager: RichPopupManager) {
        guard richPopupManager.shouldShowAttachments || richPopupManager.shouldAllowEditAttachments else { return nil }
        guard let manager = richPopupManager.attachmentManager else { return nil }
        self.popupManager = richPopupManager
        self.popupAttachmentsManager = manager
    }
    
    // MARK: Loadable
    
    private var cancelableFetch: AGSCancelable?
    
    override func doStartLoading(_ retrying: Bool) {
        
        if retrying { clear() }
        
        guard let popupManager = popupManager else {
            loadDidFinishWithError(NSError.unknown)
            return
        }
        
        guard popupManager.shouldShowAttachments else {
            preconditionFailure("The `RichPopupAttachmentsManager` should not perform a load operation if showing attachments is not supported.")
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
    
    override func doCancelLoading() {
        
        cancelableFetch?.cancel()
        
        clear()
    }
    
    // MARK: Fetched and Staged Attachments
    
    private var fetchedAttachments = [AGSPopupAttachment]()
    
    private var stagedAttachments = [RichPopupStagedAttachment]()
    
    var hasStagedAttachments: Bool {
        return !stagedAttachments.isEmpty
    }
    
    @discardableResult
    func add(stagedAttachment: RichPopupStagedAttachment) throws -> Int {
        
        guard let popupManager = popupManager, popupManager.shouldAllowEditAttachments else {
            throw InvalidOperation()
        }
        
        stagedAttachments.append(stagedAttachment)
        
        return stagedAttachments.endIndex
    }
    
    
    func deleteAttachment(at index: Int) throws -> Bool {
        
        guard let popupManager = popupManager, popupManager.shouldAllowEditAttachments else {
            throw InvalidOperation()
        }
        
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
    
    // MARK: Popup Manager Lifecycle
    //
    // Used in the `RichPopupManager`.
    //
    
    func commitStagedAttachments(_ completion: @escaping () -> Void) {
        
        // Add Staged Attachments
        let newAttachments = self.stagedAttachments
        
        let dispatchGroup = DispatchGroup()
        
        newAttachments.forEach { (attachment) in

            if let photoAttachment = attachment as? RichPopupStagedPhotoAttachment {

                dispatchGroup.enter()
                popupAttachmentsManager.addAttachment(withUIImagePickerControllerInfoDictionary: photoAttachment.info,
                                                      name: photoAttachment.name ?? "Image",
                                                      preferredSize: photoAttachment.preferredSize,
                                                      completion: { (_) in dispatchGroup.leave() })
            }
            else {
                
                popupAttachmentsManager.addAttachment(with: attachment.attachmentData,
                                                      name: attachment.name ?? "Attachment",
                                                      contentType: attachment.attachmentMimeType,
                                                      preferredSize: attachment.preferredSize)
            }
        }
        
        dispatchGroup.notify(queue: OperationQueue.current?.underlyingQueue ?? .main) { [weak self] in
            
            guard let self = self else { return }
            
            self.discardStagedAttachments()
            
            completion()
        }
    }
        
    func discardStagedAttachments() {
        
        fetchedAttachments = popupAttachmentsManager.filteredAndSortedAttachments()
        stagedAttachments.removeAll()
    }
    
    private func clear() {
        
        fetchedAttachments.removeAll()
        stagedAttachments.removeAll()
    }
    
    // MARK: Thumbnail Images Cache
    
    // A `CachedImage` is a hashable class that contains an optional `UIImage`.
    //
    // Not all attachments will generate a thumbnail.
    // If we've attempted to generate a thumbnail for an attachment that doesn't have one,
    // we want the cache to reflect that we've already tried so that we don't try again.
    //
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
        
        // We don't want to perform the `generateThumbnail` operation more than once.
        guard thumbnailCache.object(forKey: attachment) == nil else {
            return
        }
        
        if let attachment = attachment as? AGSPopupAttachment {

            guard self.fetchedAttachments.contains(attachment) else {
                throw InvalidOperation()
            }
        }
        else if let attachment = attachment as? RichPopupStagedAttachment {
            
            guard self.stagedAttachments.contains(attachment) else {
                throw InvalidOperation()
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
}

// MARK: Attachment retrieval, UI elements interface

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
    
    func loadAttachment(at index: Int) throws {
        
        guard let attachment = attachment(at: index) else {
            throw InvalidOperation()
        }
        
        if let attachment = attachment as? AGSLoadable {
            attachment.load(completion: nil)
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

// MARK:- Popup Attachment Previewable

// `AGSPopupAttachment` has automatic conformance to `RichPopupPreviewableAttachment`.
extension AGSPopupAttachment: RichPopupPreviewableAttachment { }

extension AGSPopupAttachment: QLPreviewItem {
    
    public var previewItemURL: URL? {
        return fileURL
    }
    
    public var previewItemTitle: String? {
        return name
    }
}

// MARK:- Error

extension RichPopupAttachmentsManager {
    struct InvalidOperation: LocalizedError {
        var localizedDescription: String { "The operation you are trying to perform is not permitted." }
    }
}
