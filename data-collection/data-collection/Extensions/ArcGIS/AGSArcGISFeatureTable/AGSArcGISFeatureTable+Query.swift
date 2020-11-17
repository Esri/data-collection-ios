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
    
    /// Query for related records for a specific table relationship regardless of whether working online (with a service feature table) or offline (with a geodatabase feature table).
    ///
    /// This function returns all query results regardless of table type.
    ///
    /// - Parameters:
    ///     - feature: Feature of which related records are requested.
    ///     - relationship: Which related table to query.
    ///     - completion: Closure providing an array of `AGSRelatedFeatureQueryResult` or an `Error` but not both.
    ///
    /// - Returns: Optionally nil `AGSCancelable` object. Maintaining a reference to this cancelable object allows the app to cancel the query in favor of a new query.
    
    @discardableResult
    func queryRelatedFeatures(forFeature feature: AGSArcGISFeature, relationship: AGSRelationshipInfo, completion: @escaping ([AGSRelatedFeatureQueryResult]?, Error?)->()) -> AGSCancelable? {
        
        let parameters = AGSRelatedQueryParameters(relationshipInfo: relationship)
        
        if let serviceFeatureTable = self as? AGSServiceFeatureTable {
            let fields = AGSQueryFeatureFields.loadAll
            return serviceFeatureTable.queryRelatedFeatures(for: feature, parameters: parameters, queryFeatureFields: fields, completion: completion)
        }
        else if let geodatabaseFeatureTable = self as? AGSGeodatabaseFeatureTable {
            return geodatabaseFeatureTable.queryRelatedFeatures(for: feature, parameters: parameters, completion: completion)
        }
        else {
            completion(nil, FeatureTableError.isNotArcGISFeatureTable)
            return nil
        }
    }
    
    /// Query for related records converted to pop-ups for a specific table relationship regardless of whether working online (with a service feature table) or offline (with a geodatabase feature table).
    ///
    /// This function offers all query results as popups regardless of table type.
    ///
    /// - Parameters:
    ///     - feature: Feature of which related records are requested.
    ///     - relationship: Which related table to query.
    ///     - completion: Closure providing an array of `AGSPopup` or an `Error` but not both.
    ///
    /// - Returns: Optionally nil `AGSCancelable` object. Maintaining a reference to this cancelable object allows the app to cancel the query in favor of a new query.
    ///
    /// - SeeAlso: `queryRelatedFeatures(forFeature feature: AGSArcGISFeature, relationship: AGSRelationshipInfo, completion: @escaping ([AGSRelatedFeatureQueryResult]?, Error?) -> ()) -> AGSCancelable?`
    
    @discardableResult
    func queryRelatedFeaturesAsPopups(forFeature feature: AGSArcGISFeature, relationship: AGSRelationshipInfo, completion: @escaping ([AGSPopup]?, Error?)->()) -> AGSCancelable? {
        
        return queryRelatedFeatures(forFeature: feature, relationship: relationship) { (results, error) in
            
            guard error == nil else {
                completion(nil, error!)
                return
            }
            
            guard let result = results?.first, let features = result.featureEnumerator().allObjects as? [AGSArcGISFeature] else {
                completion(nil, FeatureTableError.queryResultsMissingFeatures)
                return
            }
            
            do {
                let popups = try features.asPopups()
                completion(popups, nil)
            }
            catch {
                completion(nil, error)
            }
        }
    }
    
    /// Query all features regardless of whether working online (with a service feature table) or offline (with a geodatabase feature table).
    ///
    /// This function offers a feature query result regardless of table type as well as the optional ability to sort.
    ///
    /// - Parameters:
    ///     - sorted: Optional sort order, defaulted nil.
    ///     - completion: Closure providing an `AGSFeatureQueryResult` object or an `Error` but not both.
    ///
    /// - Returns: Optionally nil `AGSCancelable` object. Maintaining a reference to this cancelable object allows the app to cancel the query in favor of a new query.
    
    @discardableResult
    func queryAllFeatures(sorted: AGSOrderBy? = nil, completion: @escaping (AGSFeatureQueryResult?, Error?) -> Void) -> AGSCancelable? {
        
        let queryParams = AGSQueryParameters.all()
        
        if let sort = sorted {
            queryParams.orderByFields.append(sort)
        }

        // Online
        if let serviceFeatureTable = self as? AGSServiceFeatureTable {
            return serviceFeatureTable.queryFeatures(with: queryParams, queryFeatureFields: .loadAll, completion: completion)
        }
        // Offline
        else if let geodatabaseFeatureTable = self as? AGSGeodatabaseFeatureTable {
            return geodatabaseFeatureTable.queryFeatures(with: queryParams, completion: completion)
        }
        // Unknown
        else {
            completion(nil, FeatureTableError.isNotArcGISFeatureTable)
            return nil
        }
    }
    
    /// Query all features converted to pop-ups regardless of whether working online (with a service feature table) or offline (with a geodatabase feature table).
    ///
    /// This function offers an array of pop-ups regardless of table type as well as the optional ability to sort.
    ///
    /// - Parameters:
    ///     - sorted: Optional sort order, defaulted nil.
    ///     - completion: Closure providing an array of `AGSPopup` objects or an `Error` but not both.
    ///
    /// - Returns: Optionally nil `AGSCancelable` object. Maintaining a reference to this cancelable object allows the app to cancel the query in favor of a new query.
    ///
    /// - SeeAlso: `func queryAllFeatures(sorted: AGSOrderBy? = nil, completion: @escaping (AGSFeatureQueryResult?, Error?) -> Void) -> AGSCancelable?`
    
    @discardableResult
    func queryAllFeaturesAsPopups(sorted: AGSOrderBy? = nil, completion: @escaping ([AGSPopup]?, Error?) -> Void) -> AGSCancelable? {
        
        return self.queryAllFeatures(sorted: sorted) { (result, error) in
            
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
            
            do {
                let popups = try features.asPopups()
                completion(popups, nil)
            }
            catch {
                completion(nil, error)
            }
        }
    }
}

// MARK: Query Parameters

private extension AGSQueryParameters {
    
    /// Return a new `AGSQueryParameters` with a `whereClause` requesting all features in the table.
    static func all() -> AGSQueryParameters {
        let query = AGSQueryParameters()
        query.whereClause = "1 = 1"
        return query
    }
}
