//// Copyright 2018 Esri
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

import Foundation

enum RichPopupManagerError: AppError {
    
    var baseCode: AppErrorBaseCode { return .RichPopupManagerError }
    
    case missingManyToOneRelationship(String)
    case invalidPopup([Error])
    case cannotRelateFeatures
    case manyToOneRecordEditingErrors([Error])
    case editingNotPermitted
    
    var errorCode: Int {
        let base = baseCode.rawValue
        switch self {
        case .missingManyToOneRelationship(_):
            return base + 1
        case .invalidPopup:
            return base + 2
        case .cannotRelateFeatures:
            return base + 3
        case .manyToOneRecordEditingErrors(_):
            return base + 4
        case .editingNotPermitted:
            return base + 5
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .missingManyToOneRelationship(let str):
            return [NSLocalizedDescriptionKey: String(format: "Missing value for many to one relationship %@", str)]
        case .invalidPopup(let errors):
            return [NSLocalizedDescriptionKey: "The record contains \(errors.count) invalid field(s).",
                    NSUnderlyingErrorKey: errors]
        case .cannotRelateFeatures:
            return [NSLocalizedDescriptionKey: "Cannot relate features."]
        case .manyToOneRecordEditingErrors(let errors):
            return [NSLocalizedDescriptionKey: "Error editing \(errors.count) many to one record(s).",
                    NSUnderlyingErrorKey: errors]
        case .editingNotPermitted:
            return [NSLocalizedDescriptionKey: "Editing isn't permitted for this popup."]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}
