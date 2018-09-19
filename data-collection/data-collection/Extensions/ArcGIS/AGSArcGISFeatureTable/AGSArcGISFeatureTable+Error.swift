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
import ArcGIS

enum FeatureTableError: AppError {
    
    case missingFeature
    case missingFeatureTable
    case missingRelationshipInfos
    case multipleQueriesFailure
    case queryResultsMissingFeatures
    case queryResultsMissingPopups
    case isNotArcGISFeatureTable
    case isNotPopupEnabled
    case cannotEditFeature
    
    var errorCode: Int {
        let base = AppErrorBaseCode.FeatureTableError
        switch self {
        case .missingFeature:
            return base + 1
        case .missingFeatureTable:
            return base + 2
        case .missingRelationshipInfos:
            return base + 3
        case .multipleQueriesFailure:
            return base + 4
        case .queryResultsMissingFeatures:
            return base + 5
        case .queryResultsMissingPopups:
            return base + 6
        case .isNotArcGISFeatureTable:
            return base + 7
        case .isNotPopupEnabled:
            return base + 8
        case .cannotEditFeature:
            return base + 9
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .missingFeature:
            return [NSLocalizedDescriptionKey: "Missing feature"]
        case .missingFeatureTable:
            return [NSLocalizedDescriptionKey: "Missing feature table"]
        case .missingRelationshipInfos:
            return [NSLocalizedDescriptionKey: "Feature does not belong to a feature table."]
        case .multipleQueriesFailure:
            return [NSLocalizedDescriptionKey: "Attempt to query table multiple times failed."]
        case .queryResultsMissingFeatures:
            return [NSLocalizedDescriptionKey: "Query result is missing features."]
        case .queryResultsMissingPopups:
            return [NSLocalizedDescriptionKey: "Query result is missing popups."]
        case .isNotArcGISFeatureTable:
            return [NSLocalizedDescriptionKey: "Feature table is not of type AGSServiceFeatureTable or AGSGeodatabaseFeatureTable."]
        case .isNotPopupEnabled:
            return [NSLocalizedDescriptionKey: "Feature table is not popup enabled."]
        case .cannotEditFeature:
            return [NSLocalizedDescriptionKey: "Feature table cannot edit (add/update) feature."]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}
