// Copyright 2021 Esri
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

@available(iOS 14.0, *)
class RichPopupStagedPhotoPickerAttachment: RichPopupStagedAttachment {
    
    private(set) var itemProvider: NSItemProvider
    
    init?(itemProvider: NSItemProvider) {
        guard itemProvider.hasRepresentationConforming(toTypeIdentifier: "public.image", fileOptions: NSItemProviderFileOptions(rawValue: 0)) else {
            return nil
        }
        self.itemProvider = itemProvider
        super.init(name: itemProvider.suggestedName)
    }
    
    override var type: AGSPopupAttachmentType { return .image }
    
    override func generateThumbnail(withSize: Float, scaleMode: AGSImageScaleMode, completion: @escaping (UIImage?) -> Void) {
        itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
            if let image = image as? UIImage {
                completion(image)
            }
        }
    }
}
