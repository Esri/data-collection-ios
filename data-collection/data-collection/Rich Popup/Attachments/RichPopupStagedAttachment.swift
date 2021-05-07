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

class RichPopupStagedAttachment: NSObject, RichPopupPreviewableAttachment {
    
    struct AttachmentData {
        let data: Data
        let mimeType: String
    }
    
    let attachmentData: AttachmentData
        
    var name: String?
    
    init(data: AttachmentData? = nil, name: String? = nil) {
        if let data = data {
            self.attachmentData = data
        }
        else {
            self.attachmentData = AttachmentData(
                data: Data(),
                mimeType: "application/octet-stream"
            )
        }
        self.name = name
        super.init()
    }
    
    /// Optionally, specify a `previewItemURL` if you would like this staged attachment available to `QLPreviewController`.
    var previewItemURL: URL?
    
    /// Complete with a `UIImage` if you would like an image displayed in the list of attachments.
    func generateThumbnail(withSize: Float, scaleMode: AGSImageScaleMode, completion: @escaping (UIImage?) -> Void) {
        completion(nil)
    }
    
    /// This is only relevant when `attachmentType` is `.image`.
    var preferredSize: AGSPopupAttachmentSize = .actual
    
    /// Specify which attachment type, this will drive which attachment cell fallback image is displayed.
    var type: AGSPopupAttachmentType { return .other }
}
