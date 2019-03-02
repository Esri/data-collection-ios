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

enum PopupSortingError: Int, AppError {
    
    var baseCode: AppErrorBaseCode { return .PopupSortingError }
    
    case missingFields = 1
    case badFields
    case invalidValueType
    
    var errorCode: Int {
        return baseCode.rawValue + self.rawValue
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

extension AGSPopup {
    
    /// Compare two `AGSPopup` objects for less than comparison based on the value of their first field.
    ///
    /// - Parameters:
    ///   - lhs: Left pop-up in comparison.
    ///   - rhs: Right pop-up in comparison.
    ///
    /// - Returns: Which pop-up's first field is less than the other.
    ///
    /// - Throws: If the two pop-ups first fields are not of the same data type.
    ///
    /// - Note: `AGSPopup` does not adhere to `Comparable` because this function needs to be able to `throw`
    /// should the two first fields not be of the same type.
    
    public static func < (lhs: AGSPopup, rhs: AGSPopup) throws -> Bool {
        
        guard let lhsField = lhs.popupDefinition.fields.first, let rhsField = rhs.popupDefinition.fields.first else {
            throw PopupSortingError.missingFields
        }
        
        do {
            let lhsManager = AGSPopupManager(popup: lhs)
            let rhsManager = AGSPopupManager(popup: rhs)
            
            guard lhsManager.fieldType(for: lhsField) == rhsManager.fieldType(for: rhsField) else {
                throw PopupSortingError.badFields
            }
            
            guard let rhsValue = rhsManager.value(for: rhsField) else {
                return true
            }
            
            guard let lhsValue = lhsManager.value(for: lhsField) else {
                return false
            }
            
            switch lhsManager.fieldType(for: lhsField) {
            case .int16:
                return (lhsValue as! Int16) < (rhsValue as! Int16)
            case .int32:
                return (lhsValue as! Int32) < (rhsValue as! Int32)
            case .float:
                return (lhsValue as! Float) < (rhsValue as! Float)
            case .double:
                return (lhsValue as! Double) < (rhsValue as! Double)
            case .text:
                return (lhsValue as! String) < (rhsValue as! String)
            case .date:
                return (lhsValue as! Date) < (rhsValue as! Date)
            default:
                throw PopupSortingError.invalidValueType
            }
        }
        catch {
            throw error
        }
    }
    
    /// Compare two `AGSPopup` objects for greater than comparison based on the value of their first field.
    ///
    /// - Parameters:
    ///   - lhs: Left pop-up in comparison.
    ///   - rhs: Right pop-up in comparison.
    ///
    /// - Returns: Which pop-up's first field is greater than the other.
    ///
    /// - Throws: If the two pop-ups first fields are not of the same data type.
    ///
    /// - Note: `AGSPopup` does not adhere to `Comparable` because this function needs to be able to `throw`
    /// should the two first fields not be of the same type.
    
    public static func > (lhs: AGSPopup, rhs: AGSPopup) throws -> Bool {
        
        guard let lhsField = lhs.popupDefinition.fields.first, let rhsField = rhs.popupDefinition.fields.first else {
            throw PopupSortingError.missingFields
        }
        
        do {
            let lhsManager = AGSPopupManager(popup: lhs)
            let rhsManager = AGSPopupManager(popup: rhs)
            
            guard lhsManager.fieldType(for: lhsField) == rhsManager.fieldType(for: rhsField) else {
                throw PopupSortingError.badFields
            }
            
            guard let rhsValue = rhsManager.value(for: rhsField) else {
                return true
            }
            
            guard let lhsValue = lhsManager.value(for: lhsField) else {
                return false
            }
            
            switch lhsManager.fieldType(for: lhsField) {
            case .int16:
                return (lhsValue as! Int16) > (rhsValue as! Int16)
            case .int32:
                return (lhsValue as! Int32) > (rhsValue as! Int32)
            case .float:
                return (lhsValue as! Float) > (rhsValue as! Float)
            case .double:
                return (lhsValue as! Double) > (rhsValue as! Double)
            case .text:
                return (lhsValue as! String) > (rhsValue as! String)
            case .date:
                return (lhsValue as! Date) > (rhsValue as! Date)
            default:
                throw PopupSortingError.invalidValueType
            }
        }
        catch {
            throw error
        }
    }
    
    public static func == (lhs: AGSPopup, rhs: AGSPopup) -> Bool {
        return (lhs.geoElement as? AGSArcGISFeature)?.objectID == (rhs.geoElement as? AGSArcGISFeature)?.objectID
    }
}
