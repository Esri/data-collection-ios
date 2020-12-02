////// Copyright 2018 Esri
////
//// Licensed under the Apache License, Version 2.0 (the "License");
//// you may not use this file except in compliance with the License.
//// You may obtain a copy of the License at
////
////   http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing, software
//// distributed under the License is distributed on an "AS IS" BASIS,
//// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//// See the License for the specific language governing permissions and
//// limitations under the License.
//
//import Foundation
//
//enum RichPopupManagerError: AppError {
//    
//    var baseCode: AppErrorBaseCode { return .RichPopupManagerError }
//    
//    case missingManyToOneRelationship(String)
//    case invalidPopup([Error])
//    case cannotRelateFeatures
//    case manyToOneRecordEditingErrors([Error])
//    case editingNotPermitted
//    case newOneToManyRelatedRecordError
//    case viewRelatedRecordError
//    case oneToManyRecordDeletionErrors([Error])
//    
//    var errorCode: Int {
//        let base = baseCode.rawValue
//        switch self {
//        case .missingManyToOneRelationship(_):
//            return base + 1
//        case .invalidPopup:
//            return base + 2
//        case .cannotRelateFeatures:
//            return base + 3
//        case .manyToOneRecordEditingErrors(_):
//            return base + 4
//        case .editingNotPermitted:
//            return base + 5
//        case .newOneToManyRelatedRecordError:
//            return base + 6
//        case .viewRelatedRecordError:
//            return base + 7
//        case .oneToManyRecordDeletionErrors(_):
//            return base + 8
//        }
//    }
//    
//    var errorUserInfo: [String : Any] {
//        switch self {
//        case .missingManyToOneRelationship(let str):
//            return [NSLocalizedDescriptionKey: String(format: "Missing value for many to one relationship %@", str)]
//        case .invalidPopup(let errors):
//            return [NSLocalizedDescriptionKey: String(format: "The record contains %d invalid field(s).", errors.count),
//                    MultipleUnderlyingErrorsKey: errors]
//        case .cannotRelateFeatures:
//            return [NSLocalizedDescriptionKey: "Cannot relate features."]
//        case .manyToOneRecordEditingErrors(let errors):
//            return [NSLocalizedDescriptionKey: String(format: "Error editing %d many to one record(s).", errors.count),
//                    MultipleUnderlyingErrorsKey: errors]
//        case .editingNotPermitted:
//            return [NSLocalizedDescriptionKey: "Editing isn't permitted for this popup."]
//        case .newOneToManyRelatedRecordError:
//            return [NSLocalizedDescriptionKey: "Cannot add a new one to many related record while editing this record."]
//        case .viewRelatedRecordError:
//            return [NSLocalizedDescriptionKey: "Cannot view this related record while editing this record."]
//        case .oneToManyRecordDeletionErrors(let errors):
//            return [NSLocalizedDescriptionKey: String(format: "Error deleting %d one to many record(s).", errors.count),
//                    MultipleUnderlyingErrorsKey: errors]
//        }
//    }
//    
//    var localizedDescription: String {
//        return errorUserInfo[NSLocalizedDescriptionKey] as! String
//    }
//}
