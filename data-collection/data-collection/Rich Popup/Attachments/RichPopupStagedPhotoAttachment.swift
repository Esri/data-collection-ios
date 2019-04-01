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

class RichPopupStagedPhotoAttachment: RichPopupStagedAttachment {
    
    private static var attachmentIncrement: Int = 1
    
    private func setAttachmentNameIncrementedNext() {
        self.name = String(format: "Photo %d", RichPopupStagedPhotoAttachment.attachmentIncrement)
        RichPopupStagedPhotoAttachment.attachmentIncrement += 1
    }
    
    override var type: AGSPopupAttachmentType { return .image }
    
    let image: UIImage
    
    var nameAsJPEG: String? {
        
        guard var jpegName = name else { return nil }
        
        let fileExtension = NSString(string: jpegName).pathExtension
        
        if fileExtension != "jpeg" && fileExtension != "jpg" {
            jpegName.append(".jpeg")
        }
        
        return jpegName
    }
    
    init?(image: UIImage) {
        
        self.image = image
        
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        
        super.init(data: data, mimeType: "image/jpeg", name: nil)
        
        setAttachmentNameIncrementedNext()
    }
    
    convenience init?(imagePickerMediaInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            return nil
        }
        
        self.init(image: image)
        
        self.previewItemURL = info[.imageURL] as? URL
    }
    
    override func generateThumbnail(withSize: Float, scaleMode: AGSImageScaleMode, completion: @escaping (UIImage?) -> Void) {
        
        // Returns the full image, allowing the UIImageView.contentMode to dictate image render rather than `AGSImageScaleMode`.
        completion(image)
    }
}
