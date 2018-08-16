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

extension AGSPopup {
    
    var feature: AGSArcGISFeature? {
        return geoElement as? AGSArcGISFeature
    }
    
    func clearSelection() {
        
        guard let layer = feature?.featureTable?.featureLayer else {
            return
        }
        
        layer.clearSelection()
    }
    
    func select() {
        
        guard
            let feature = feature,
            let table = feature.featureTable,
            let layer = table.featureLayer
            else {
                return
        }
        
        layer.select(feature)
    }
    
    var asManager: AGSPopupManager {
        return AGSPopupManager(popup: self)
    }
    
    var isEditable: Bool {
        return asManager.shouldAllowEdit
    }
    
    func relate(toPopup popup: AGSPopup, relationshipInfo info: AGSRelationshipInfo) {
        
        guard
            let feature = geoElement as? AGSArcGISFeature,
            let relatedFeature = popup.geoElement as? AGSArcGISFeature
            else {
                return
        }
        feature.relate(to: relatedFeature, relationshipInfo: info)
    }
    
    func unrelate(toPopup popup: AGSPopup) {
        
        guard
            let feature = geoElement as? AGSArcGISFeature,
            let relatedFeature = popup.geoElement as? AGSArcGISFeature
            else {
                return
        }
        feature.unrelate(to: relatedFeature)
    }
    
    func relationship(withPopup popup: AGSPopup) -> AGSRelationshipInfo? {
        
        guard
            let feature = geoElement as? AGSArcGISFeature,
            let relationships = feature.relatedRecordsInfos,
            let relatedFeature = popup.geoElement as? AGSArcGISFeature,
            let relatedFeatureTable = relatedFeature.featureTable as? AGSArcGISFeatureTable
            else {
                return nil
        }
        
        return relationships.first { (info) -> Bool in
            return info.relatedTableID == relatedFeatureTable.serviceLayerID
        }
    }
    
    var isFeatureAddedToTable: Bool {
        
        guard let feature = geoElement as? AGSArcGISFeature else {
            return false
        }
        
        return feature.objectID != nil
    }
    
    var tableName: String? {
        return (geoElement as? AGSArcGISFeature)?.featureTable?.tableName
    }
    
    var recordType: ArcGISRecordType? {
        
        guard let feature = geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
            return nil
        }
        
        return featureTable.featureLayer != nil ? .feature : .record
    }
}

enum ArcGISRecordType: String {
    case record, feature
}

extension Collection where Iterator.Element == AGSPopup {
    
    /**
     This function is used to find the nearest point in a collection of points to another point.
     
     Querying a feature layer returns a collection of features, the order for which was in the order
     the feature was discovered in traverse by the backing service as opposed to distance from the query's point.
     */
    func popupNearestTo(mapPoint: AGSPoint) -> AGSPopup? {
        guard count > 0 else {
            return nil
        }
        let sorted = self.sorted(by: { (popupA, popupB) -> Bool in
            let deltaA = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: popupA.geoElement.geometry!)
            let deltaB = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: popupB.geoElement.geometry!)
            return deltaA < deltaB
        })
        return sorted.first
    }
}

// MARK: Sorting

extension AGSPopup {
    
    public static func < (lhs: AGSPopup, rhs: AGSPopup) throws -> Bool {
        
        guard let lhsField = lhs.popupDefinition.fields.first, let rhsField = rhs.popupDefinition.fields.first else {
            throw PopupSortingError.missingFields
        }
        
        do {
            return try autoreleasepool { () throws -> Bool in
                
                let lhsManager = AGSPopupManager(popup: lhs)
                let rhsManager = AGSPopupManager(popup: rhs)
                
                guard lhsManager.fieldType(for: lhsField) == rhsManager.fieldType(for: rhsField) else {
                    throw PopupSortingError.badFields
                }
                
                guard let lhsValue = lhsManager.value(for: lhsField), let rhsValue = rhsManager.value(for: rhsField) else {
                    throw PopupSortingError.noValues
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
        }
        catch {
            throw error
        }
    }
    
    public static func > (lhs: AGSPopup, rhs: AGSPopup) throws -> Bool {
        
        guard let lhsField = lhs.popupDefinition.fields.first, let rhsField = rhs.popupDefinition.fields.first else {
            throw PopupSortingError.missingFields
        }
        
        do {
            return try autoreleasepool { () throws -> Bool in
                
                let lhsManager = AGSPopupManager(popup: lhs)
                let rhsManager = AGSPopupManager(popup: rhs)
                
                guard lhsManager.fieldType(for: lhsField) == rhsManager.fieldType(for: rhsField) else {
                    throw PopupSortingError.badFields
                }
                
                guard let lhsValue = lhsManager.value(for: lhsField), let rhsValue = rhsManager.value(for: rhsField) else {
                    throw PopupSortingError.noValues
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
        }
        catch {
            throw error
        }
    }
}

extension Array where Iterator.Element == AGSPopup {
    
    mutating func sortPopupsByFirstField(_ order: AGSSortOrder = .ascending) throws {
        
        do {
            switch order {
            case .ascending:
                try sort { (left, right) -> Bool in return try left < right }
            case .descending:
                try sort { (left, right) -> Bool in return try left > right }
            }
        }
        catch {
            throw error
        }
    }
}

