//// Copyright 2017 Esri
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

protocol AppError: CustomNSError, LocalizedError { }

enum AppFilesError: AppError  {
    
    case cannotBuildPath(String)
    
    var errorCode: Int {
        switch self {
        case .cannotBuildPath(_):
            return 1001
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .cannotBuildPath(let path):
            return [NSLocalizedDescriptionKey: "Cannot build path \(path)"]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}

enum RelatedRecordsManagerError: AppError {
    
    case featureMissingTable
    case missingManyToOneRelationship(String)
    case invalidPopup
    case cannotRelateFeatures

    var errorCode: Int {
        switch self {
        case .featureMissingTable:
            return 2001
        case .missingManyToOneRelationship(_):
            return 2002
        case .invalidPopup:
            return 2003
        case .cannotRelateFeatures:
            return 2004
        }
    }

    var errorUserInfo: [String : Any] {
        switch self {
        case .featureMissingTable:
            return [NSLocalizedDescriptionKey: "Feature does not belong to a feature table"]
        case .missingManyToOneRelationship(let str):
            return [NSLocalizedDescriptionKey: "Missing value for many to one relationship \(str)"]
        case .invalidPopup:
            return [NSLocalizedDescriptionKey: "Popup with related records in invalid."]
        case .cannotRelateFeatures:
            return [NSLocalizedDescriptionKey: "Features or Relationship Info missing."]
        }
    }

    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}

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
        switch self {
        case .missingFeature:
            return 3001
        case .missingFeatureTable:
            return 3002
        case .missingRelationshipInfos:
            return 3003
        case .multipleQueriesFailure:
            return 3004
        case .queryResultsMissingFeatures:
            return 3005
        case .queryResultsMissingPopups:
            return 3006
        case .isNotArcGISFeatureTable:
            return 3007
        case .isNotPopupEnabled:
            return 3008
        case .cannotEditFeature:
            return 3009
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

enum PopupSortingError : AppError {
    
    case missingFields
    case badFields
    case invalidValueType
    
    var errorCode: Int {
        switch self {
        case .missingFields:
            return 4001
        case .badFields:
            return 4002
        case .invalidValueType:
            return 4004
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .missingFields:
            return [NSLocalizedDescriptionKey: "A popup you are comparing does not have any fields."]
        case .badFields:
            return [NSLocalizedDescriptionKey: "Both popups fields must be of the same type."]
        case .invalidValueType:
            return [NSLocalizedDescriptionKey: "A popup you are comparing contains an invalid type."]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}

enum AppGeocoderError: AppError {
    
    case missingAddressAttribute
    
    var errorCode: Int {
        switch self {
        case .missingAddressAttribute:
            return 5001
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .missingAddressAttribute:
            return [NSLocalizedDescriptionKey: "Missing Address (for online locator) or Match_addr (for offline locator) in attributes."]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}

enum AppLoadableError: AppError {
    
    case canceledLoad
    
    var errorCode: Int {
        switch self {
        case .canceledLoad:
            return 6001
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .canceledLoad:
            return [NSLocalizedDescriptionKey: "Did cancel load."]
        }
    }
    
    var canceledLoad: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}
