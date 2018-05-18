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
        
        let fields = AGSQueryFeatureFields.loadAll
        let parameters = AGSRelatedQueryParameters(relationshipInfo: relationship)
        
        if let serviceFeatureTable = self as? AGSServiceFeatureTable {
            serviceFeatureTable.queryRelatedFeatures(for: feature, parameters: parameters, queryFeatureFields: fields, completion: completion)
        }
        else if let geodatabaseFeatureTable = self as? AGSGeodatabaseFeatureTable {
            geodatabaseFeatureTable.queryRelatedFeatures(for: feature, parameters: parameters, completion: completion)
        }
        else {
            completion(nil, FeatureTableError.isNotArcGISFeatureTable)
            return
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
            
            guard let popups = features.asPopups else {
                completion(nil, FeatureTableError.isNotPopupEnabled)
                return
            }
            
            completion(popups, nil)
        }
    }
    
    func queryRelatedFeatures(forFeature feature: AGSArcGISFeature, relationships:[AGSRelationshipInfo], completion: @escaping ([AGSRelatedFeatureQueryResult]?, Error?) -> Void) {
                
        let group = DispatchGroup()
        var finalError: NSError?
        var finalResults = [AGSRelatedFeatureQueryResult]()
        
        for info in relationships {
            
            group.enter()
            queryRelatedFeatures(forFeature: feature, relationship: info) { (results, error) in

                if error != nil {
                    finalError = FeatureTableError.multipleQueriesFailure as NSError
                }

                if let additionalResults = results {
                    finalResults += additionalResults
                }

                group.leave()
            }
        }
        
        group.notify(queue: OperationQueue.current?.underlyingQueue ?? .main) {
            completion(finalResults, finalError)
        }
    }

    func queryRelatedFeaturesAsPopups(forFeature feature: AGSArcGISFeature, relationships:[AGSRelationshipInfo], completion: @escaping ([AGSPopup]?, Error?) -> Void) {
        
        let group = DispatchGroup()
        var finalError: NSError?
        var finalResults = [AGSPopup]()
        
        for info in relationships {
            
            group.enter()
            queryRelatedFeaturesAsPopups(forFeature: feature, relationship: info) { (results, error) in
                
                if error != nil {
                    finalError = FeatureTableError.multipleQueriesFailure as NSError
                }
                
                if let additionalResults = results {
                    finalResults += additionalResults
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: OperationQueue.current?.underlyingQueue ?? .main) {
            completion(finalResults, finalError)
        }
    }
}
