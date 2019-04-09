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

enum FeatureTableError: Int, AppError {
    
    var baseCode: AppErrorBaseCode { return .FeatureTableError }
    
    case invalidFeature = 1
    case invalidFeatureTable
    case missingRelationshipInfos
    case queryResultsMissingFeatures
    case queryResultsMissingPopups
    case isNotArcGISFeatureTable
    case isNotPopupEnabled
    case doesNotHaveAttachments
    case cannotEditFeature
    case featuresAreNotFromTheSameTable
    
    var errorCode: Int {
        return baseCode.rawValue + self.rawValue
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .invalidFeature:
            return [NSLocalizedFailureReasonErrorKey: "The pop-up's geo element is not an instance of AGSArcGISFeature.",
                    NSLocalizedDescriptionKey: "Invalid feature."]
        case .invalidFeatureTable:
            return [NSLocalizedFailureReasonErrorKey: "The pop-up's feature's owning feature table is not an instance of AGSArcGISFeatureTable.",
                    NSLocalizedDescriptionKey: "Invalid feature table."]
        case .missingRelationshipInfos:
            return [NSLocalizedFailureReasonErrorKey: "AGSArcGISFeatureTable is missing AGSRelationshipInfos.",
                    NSLocalizedDescriptionKey: "Missing relationship."]
        case .queryResultsMissingFeatures:
            return [NSLocalizedFailureReasonErrorKey: "Query result is missing features.",
                    NSLocalizedDescriptionKey: "Missing features."]
        case .queryResultsMissingPopups:
            return [NSLocalizedFailureReasonErrorKey: "Query result is missing pop-ups.",
                    NSLocalizedDescriptionKey: "Missing popups."]
        case .isNotArcGISFeatureTable:
            return [NSLocalizedFailureReasonErrorKey: "Feature table is not of type AGSServiceFeatureTable or AGSGeodatabaseFeatureTable.",
                    NSLocalizedDescriptionKey: "Invalid feature table."]
        case .isNotPopupEnabled:
            return [NSLocalizedFailureReasonErrorKey: "The web map's feature table is not popup enabled.",
                    NSLocalizedDescriptionKey: "Not configured for pop-ups."]
        case .doesNotHaveAttachments:
            return [NSLocalizedFailureReasonErrorKey: "Feature table is not configured to have attachments.",
                    NSLocalizedDescriptionKey: "Not configured for attachments."]
        case .cannotEditFeature:
            return [NSLocalizedFailureReasonErrorKey: "Feature table is not configured for editing (add/update) a feature.",
                    NSLocalizedDescriptionKey: "Cannot edit (add/update/delete) feature."]
        case .featuresAreNotFromTheSameTable:
            return [NSLocalizedFailureReasonErrorKey: "Features are not from the same table.",
                    NSLocalizedDescriptionKey: "Features are not the same type."]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}
