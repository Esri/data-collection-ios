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

extension AGSArcGISFeatureTable {
    
    func isPopupEnabledFor(relationshipInfo: AGSRelationshipInfo) -> Bool {
        
        guard let relatedTables = relatedTables() else {
            return false
        }
        
        let operativeID = relationshipInfo.relatedTableID
        
        for table in relatedTables {
            if table.serviceLayerID == operativeID {
                return table.isPopupActuallyEnabled
            }
        }
        
        return false
    }
    
    func queryRelatedFeatures(forFeature feature: AGSArcGISFeature, relationship: AGSRelationshipInfo, completion: @escaping ([AGSRelatedFeatureQueryResult]?, Error?)->()) {
        
        let parameters = AGSRelatedQueryParameters(relationshipInfo: relationship)
        
        if let serviceFeatureTable = self as? AGSServiceFeatureTable {
            let fields = AGSQueryFeatureFields.loadAll
            serviceFeatureTable.queryRelatedFeatures(for: feature, parameters: parameters, queryFeatureFields: fields, completion: completion)
        }
        else if let geodatabaseFeatureTable = self as? AGSGeodatabaseFeatureTable {
            geodatabaseFeatureTable.queryRelatedFeatures(for: feature, parameters: parameters, completion: completion)
        }
        else {
            completion(nil, FeatureTableError.isNotArcGISFeatureTable)
        }
    }
    
    func queryRelatedFeaturesAsPopups(forFeature feature: AGSArcGISFeature, relationship: AGSRelationshipInfo, completion: @escaping ([AGSPopup]?, Error?)->()) {
        
        queryRelatedFeatures(forFeature: feature, relationship: relationship) { (results, error) in
            
            guard error == nil else {
                completion(nil, error!)
                return
            }
            
            guard let result = results?.first, let features = result.featureEnumerator().allObjects as? [AGSArcGISFeature] else {
                completion(nil, FeatureTableError.queryResultsMissingFeatures)
                return
            }
            
            guard let popups = features.asPopups() else {
                completion(nil, FeatureTableError.isNotPopupEnabled)
                return
            }
            
            completion(popups, nil)
        }
    }
    
    func queryAllFeatures(sorted: AGSOrderBy? = nil, completion: @escaping (AGSFeatureQueryResult?, Error?) -> Void) {
        
        let queryParams = AGSQueryParameters.all()
        
        if let sort = sorted {
            queryParams.orderByFields.append(sort)
        }

        // Online
        if let serviceFeatureTable = self as? AGSServiceFeatureTable {
            serviceFeatureTable.queryFeatures(with: queryParams, queryFeatureFields: .loadAll, completion: completion)
        }
        // Offline
        else if let geodatabaseFeatureTable = self as? AGSGeodatabaseFeatureTable {
            geodatabaseFeatureTable.queryFeatures(with: queryParams, completion: completion)
        }
        // Unknown
        else {
            completion(nil, FeatureTableError.isNotArcGISFeatureTable)
            return
        }
    }
    
    func queryAllFeaturesAsPopups(sorted: AGSOrderBy? = nil, completion: @escaping ([AGSPopup]?, Error?) -> Void) {
        
        self.queryAllFeatures(sorted: sorted) { (result, error) in
            
            guard error == nil else {
                print("[Error: Service Feature Table Query]", error!.localizedDescription)
                completion(nil, error!)
                return
            }
            
            guard let result = result else {
                print("[Error: Service Feature Table Query] unknown error")
                completion(nil, FeatureTableError.queryResultsMissingFeatures)
                return
            }
            
            guard let features = result.featureEnumerator().allObjects as? [AGSArcGISFeature] else {
                completion(nil, FeatureTableError.queryResultsMissingFeatures)
                return
            }
            
            guard let popups = features.asPopups() else {
                completion(nil, FeatureTableError.isNotPopupEnabled)
                return
            }
            
            completion(popups, nil)
            return
        }
    }
    
    func performEdit(feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        // Update
        if canUpdate(feature) {
            performEdit(type: .update, forFeature: feature, completion: completion)
        }
        // Add
        else if canAddFeature {
            performEdit(type: .add, forFeature: feature, completion: completion)
        }
        else {
            completion(FeatureTableError.cannotEditFeature)
        }
    }
    
    func performDelete(feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        if canDelete(feature) {
            performEdit(type: .delete, forFeature: feature, completion: completion)
        }
        else {
            completion(FeatureTableError.cannotEditFeature)
        }
    }
    
    private func performEdit(type: EditType, forFeature feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        guard appContext.isLoggedIn else {
            assert(appContext.isLoggedIn, "User must be authenticated to perform edits.")
            completion(FeatureTableError.cannotEditFeature)
            return
        }
        
        let editClosure:(Error?) -> Void = { error in
            
            guard error == nil else {
                print("[Error: Feature Service Table] could not edit", error!.localizedDescription)
                completion(error!)
                return
            }
            
            // If online, apply edits.
            guard let serviceFeatureTable = self as? AGSServiceFeatureTable else {
                completion(nil)
                return
            }
            
            serviceFeatureTable.applyEdits(completion: { (results, error) in
                
                guard error == nil else {
                    print("[Error: Feature Service Table] could not apply edits", error!.localizedDescription)
                    completion(error!)
                    return
                }
                
                if type != .delete {
                    feature.refreshObjectID()
                }
                else {
                    feature.objectID = nil
                }
                
                completion(nil)
            })
        }
        
        switch type {
        case .update: update(feature, completion: editClosure)
        case .delete: delete(feature, completion: editClosure)
        case .add: add(feature, completion: editClosure)
        }
    }
    
    func createPopup() -> AGSPopup? {
        
        guard canAddFeature, let feature = createFeature() as? AGSArcGISFeature, let popupDefinition = popupDefinition else {
                return nil
        }
        
        return AGSPopup(geoElement: feature, popupDefinition: popupDefinition)
    }
}
