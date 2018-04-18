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

extension AGSServiceFeatureTable {
    
    func queryRelatedFeatures(`for` feature: AGSArcGISFeature, queryFeatureFields: AGSQueryFeatureFields, completion: @escaping ([AGSRelatedFeatureQueryResult]?, Error?) -> Void) {
        
        guard let relationshipInfos = layerInfo?.relationshipInfos else {
            let error = NSError(domain: "com.esri.runtime.data-collection", code: 1000, userInfo: [NSLocalizedDescriptionKey : "LayerInfo contains no relationshipInfos."])
            completion(nil, error)
            return
        }
        
        queryRelatedFeatures(for: feature, withRelationships: relationshipInfos, queryFeatureFields: queryFeatureFields, completion: completion)
    }
    
    func queryRelatedFeatures(`for` feature: AGSArcGISFeature, withRelationships relationships:[AGSRelationshipInfo], queryFeatureFields: AGSQueryFeatureFields, completion: @escaping ([AGSRelatedFeatureQueryResult]?, Error?) -> Void) {
        
        let group = DispatchGroup()
        var finalError: NSError?
        var finalResults = [AGSRelatedFeatureQueryResult]()
        
        for info in relationships {
            
            let parameters = AGSRelatedQueryParameters(relationshipInfo: info)
            
            group.enter()
            queryRelatedFeatures(for: feature, parameters: parameters, queryFeatureFields: queryFeatureFields) { results, error in
                
                if error != nil {
                    finalError = NSError(domain: "com.esri.runtime.data-collection", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Error Querying Related Records"])
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
