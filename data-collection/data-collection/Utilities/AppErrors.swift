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

enum AppFilesError: Error, CustomNSError, LocalizedError  {
    
    case cannotBuildPath(String)
    
    var errorCode: Int {
        switch self {
        case .cannotBuildPath(_):
            return 0001
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

enum AssetsError: Error {
    
    case missingAsset(String)
    
    var errorCode: Int {
        switch self {
        case .missingAsset(_):
            return 1001
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .missingAsset(let name):
            return [NSLocalizedDescriptionKey: "Asset missing for name \(name)"]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}

enum RelatedRecordsManagerError: Error, CustomNSError, LocalizedError {
    
    case featureMissingTable
    
    var errorCode: Int {
        switch self {
        case .featureMissingTable:
            return 2001
        }
    }

    var errorUserInfo: [String : Any] {
        switch self {
        case .featureMissingTable:
            return [NSLocalizedDescriptionKey: "Feature does not belong to a feature table"]
        }
    }

    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}

enum FeatureTableError: Error, CustomNSError, LocalizedError {
    
    case missingFeature
    case missingFeatureTable
    case missingRelationshipInfos
    case multipleQueriesFailure
    case queryResultsMissingFeatures
    case queryResultsMissingPopups
    case isNotArcGISFeatureTable
    case isNotPopupEnabled

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
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}
