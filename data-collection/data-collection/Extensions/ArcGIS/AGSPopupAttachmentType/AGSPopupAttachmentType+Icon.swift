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

extension AGSPopupAttachmentType {
    
    var icon: UIImage {
        switch self {
        case .image:
            return #imageLiteral(resourceName: "AttachmentImage")
        case .video:
            return #imageLiteral(resourceName: "AttachmentVideo")
        case .document:
            return #imageLiteral(resourceName: "AttachmentDocument")
        case .other:
            return #imageLiteral(resourceName: "AttachmentOther")
        @unknown default:
            fatalError("Unsupported case \(self).")
        }
    }
}
